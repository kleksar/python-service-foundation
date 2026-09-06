# PostgreSQL and SQLAlchemy

## Applicability and decisions

Apply when a feature needs relational persistence, transactions, constraints, or querying that PostgreSQL should own. Do not add a database for an otherwise stateless webhook or API client. Durable state requirements come from the feature, not from the availability of this recipe.

This document owns PostgreSQL/SQLAlchemy integration. Read [repo](../patterns/repo.md), [transactions](../patterns/transaction.md), [schemas](../patterns/schemas.md), [errors](../patterns/errors.md), [settings](../conventions/settings.md), and [Alembic](alembic.md) for their canonical responsibilities.

Decide before implementation:

- Data ownership, retention, identifiers, uniqueness, relationships, and access patterns.
- Transaction boundaries and concurrency behavior for business operations.
- Supported PostgreSQL version/extensions and deployment topology, including any external pooler.
- Connection budget across all API workers, job processes, deployments, migrations, and tests.
- Availability, backup/restore, credential rotation, and schema deployment ownership.

Async SQLAlchemy with asyncpg is the default recommendation for an async application. A synchronous application may choose a synchronous driver deliberately; do not mix sync database I/O into an async service by accident.

## Dependencies and layout

For the async path:

```sh
uv add 'sqlalchemy[asyncio]' asyncpg
```

If schemas exist, add their directly imported validation dependency explicitly. Add Alembic according to its [recipe](alembic.md), not a `create_all()` startup fallback. Lock versions and exercise the real driver/server combination, including any pooler-specific behavior.

Typical ownership after a feature actually needs storage:

- `src/app/<feature>/repo.py`: technology-neutral persistence port used by the feature.
- `src/app/<feature>/schemas.py`: application inputs and results.
- `src/app/<feature>/models.py`: owner-local SQLAlchemy mappings, isolated from the application service.
- `src/app/infra/postgres/database.py`: engine and session-factory construction.
- `src/app/infra/postgres/<feature>/repo.py`: implementation of that same feature repo contract.
- Feature and adapter `unit_of_work.py` only when an explicit transactional contract is needed.

One repo port and its implementation represent one semantic repo. Do not introduce global `repos/`, generic CRUD bases, or a second gateway layer without a separate responsibility. Table mappings may be owner-local while application code remains independent of SQLAlchemy, as specified by [architecture contracts](../architecture/contracts.md).

## Engine, session, and transaction lifecycle

Construct the engine in the process composition root from already validated settings. Creating a factory should not read environment implicitly. Close the engine with `await engine.dispose()` on normal shutdown and on partial startup failure.

A process owns its engine/pool; an operation owns its session/transaction. An `AsyncSession` is mutable transaction state and must not be shared across concurrent tasks. A background job gets its own persistence context, never the session from the request that enqueued it.

Illustrative factory, not a preinstalled abstraction:

```python
from sqlalchemy.ext.asyncio import AsyncEngine, AsyncSession, async_sessionmaker


def create_session_factory(engine: AsyncEngine) -> async_sessionmaker[AsyncSession]:
    return async_sessionmaker(engine, expire_on_commit=False)
```

The consuming project must choose and test its transaction mode, including SQLAlchemy autobegin behavior. An explicit UoW may disable autobegin and enforce one-shot use; do not copy that machinery unless the contract benefits from it. [Transactions](../patterns/transaction.md) owns commit/rollback authority.

Use parameterized SQL/SQLAlchemy expressions. Hide bound parameters in SQLAlchemy error output when data can be sensitive, but do not mistake `hide_parameters=True` for complete DSN/log sanitization. Disable query echo in production unless its safe and bounded diagnostic use is explicitly accepted.

Bound connection acquisition and queries according to the operation deadline. `pool_pre_ping` may help reject stale pooled connections but does not retry a transaction or guarantee recovery from a failure after a write. Total pool capacity must account for process count and rolling-deployment overlap, not just one engine's `pool_size`.

## Mapping, invariants, and concurrency

Define column nullability, FK behavior, unique constraints, and critical CHECK constraints from the persistence contract. Application validation and database enforcement protect different boundaries. A pre-insert existence check is not a replacement for a database unique constraint under concurrency.

Translate only known constraint violations into named application outcomes, using stable constraint identifiers or inspected driver metadata. Do not map every `IntegrityError` to “already exists.” Handle rollback and resource cleanup after a failed statement/commit before attempting other work.

Specify ordering and bounds for query results. Load relationships deliberately and map results while the session is valid; avoid accidental async lazy loads or detached ORM objects escaping as application DTOs. Test query count when a real N+1 regression is material, not as a blanket abstraction requirement.

For concurrent updates, choose a concrete strategy: database atomic statement, optimistic version check, or deliberate lock under an isolation level. If deadlock/serialization failures are retried, retry the entire replay-safe transaction with a bounded policy, not an isolated statement after partial business work. External side effects need [idempotency](../patterns/idempotency.md) or a durable handoff; a database transaction does not make a remote API call atomic.

## Readiness and deployment

A connectivity probe should acquire a connection and execute a bounded minimal query. This demonstrates connectivity, not schema compatibility. Migration state is a separate deployment check.

Expected connection/driver failures can make a dependency-aware process unready. Keep programmer errors visible, sanitize DSNs, and distinguish startup failure policy from temporary runtime unavailability. Liveness should not depend on PostgreSQL.

Use least-privilege application credentials and separate migration privilege when practical. TLS, secret provisioning, backups, restore verification, and retention are deployment requirements, not guaranteed by a local Compose container. Do not publish a database port publicly as a convenience default.

## Acceptance checks

1. Run repo tests against a real PostgreSQL server of the supported version, with migrations applied. SQLite and fake sessions do not prove PostgreSQL behavior.
2. Verify application input/result mapping and actual PK/FK/nullability/unique/critical CHECK behavior, including the known error translations.
3. Exercise commit, rollback on exception, rollback without successful commit when promised, failed commit cleanup, and session closure. Concurrent tasks must not share session state.
4. Test a representative concurrent duplicate/update race through the chosen database invariant; a sequential unit test cannot prove race safety.
5. Check engine cleanup and the real unavailable/recovery behavior, including connection acquisition failure, not only a mocked failed query.
6. Isolate tests with a dedicated database/schema or uniquely owned data. A rollback fixture does not clean writes committed by a separate process/session; arrange explicit owned cleanup for those tests.
7. Verify fresh migration and data-preserving upgrade as described in [Alembic](alembic.md). Never run destructive cleanup against a developer's or production database by inference from its name.

## Sources and limits

Inspected [Vitok database factories](https://github.com/kleksar/vitok/blob/6dc2ad3f75dd3860973cde08ea68f955af7fc4e2/src/vitok/infra/postgres/database.py) and [transaction implementation](https://github.com/kleksar/vitok/blob/6dc2ad3f75dd3860973cde08ea68f955af7fc4e2/src/vitok/infra/postgres/unit_of_work.py). Vitok declared `sqlalchemy[asyncio]>=2.0.52` and `asyncpg>=0.31.0`; these are historical source constraints, not dependencies of this seed.

Upstream references: [SQLAlchemy async documentation](https://docs.sqlalchemy.org/en/20/orm/extensions/asyncio.html) and [PostgreSQL documentation](https://www.postgresql.org/docs/). They were not fetched for this transfer. The illustrative factory and acceptance checks must be validated in the project that adds PostgreSQL; the seed does not run a database.
