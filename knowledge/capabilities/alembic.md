# Alembic

## Applicability and ownership

Apply when a SQLAlchemy-backed database schema needs versioned evolution. Add migrations with the first real schema, not a placeholder database. A production schema is not initialized by application startup calling `metadata.create_all()`.

This recipe owns Alembic integration and migration acceptance. [PostgreSQL](postgres.md) owns the database adapter; [transactions](../patterns/transaction.md) owns business transaction authority; [document lifecycle](../governance/document-lifecycle.md) distinguishes current specifications from historical implementation artifacts.

Before creating the first revision, decide:

- Which database/schema and SQLAlchemy metadata set are owned by this migration history.
- Who executes migrations and what credentials/permissions are available.
- Whether deployment permits downtime or requires old and new app versions to coexist.
- Whether downgrade is supported; if not, what restore/forward-repair procedure is promised.
- How migration execution is serialized across deployment jobs.

## Dependencies and layout

Alembic is needed in the environment that creates, checks, and executes migrations. A separate migration dependency group keeps it out of an application image that never runs migrations:

```sh
uv add --group migration alembic
```

If production runs a migration job, that job must explicitly install the migration group. “It is a dev tool” is not an excuse for a deployment command to lack its dependency. Use the same locked package/driver versions when checking and applying a migration.

Create `alembic.ini`, `migrations/env.py`, the revision template, and `migrations/versions/` when migration ownership exists. The initial Alembic scaffolding is a development tool's one-time output inside the consuming project, not a foundation project-generator or runtime module profile.

`env.py` imports only the metadata/mappings required to assemble the owned schema and the migration configuration boundary. It must not import the API application to discover models. If the application uses an async driver, use Alembic's documented async connection bridge rather than invoking async SQL from a synchronous migration function directly.

Read the database URL through the actual settings contract and pass it safely to the engine. Do not log credentials or rely on naive string concatenation. Alembic/ConfigParser interpolation treats `%` specially; test credentials containing reserved characters if routing a URL through configuration options. A direct programmatic connection path can avoid that interpolation boundary.

## Authoring and reviewing a revision

Once configured, ordinary commands are:

```sh
uv run --group migration alembic revision --autogenerate -m "add order persistence"
uv run --group migration alembic upgrade head
uv run --group migration alembic check
```

Run them only against the intended environment. Autogenerate is a proposal, not an approved migration: inspect column types, server defaults, nullability, constraint/index names, relationships, schema qualification, and data transformations. A rename can be generated as drop/add; check destructive changes explicitly.

Keep revision code self-contained enough to run against the historical schema. Do not import today's service or mutable ORM model to perform a data backfill in an old revision. Use SQLAlchemy/Alembic operations and revision-local table definitions as needed. A business application transaction policy does not automatically govern DDL; document operations that cannot execute in the migration's normal transaction mode.

Use meaningful revision descriptions and Alembic's normal revision identifiers. Do not impose Vitok's gapless numbered filenames, legacy-history checks, or custom graph parser. A single head is a useful default for one service's deployment chain, but multiple heads must be resolved intentionally rather than choosing one silently. If a project truly needs multiple branches/bases, specify and test that topology.

Treat a migration already used in a shared environment as immutable history. Correct it with a new revision unless an explicit coordinated history repair is authorized. Do not `stamp head` an existing database as a substitute for verifying its schema; stamping changes Alembic's record, not the tables.

## Safe data and deployment changes

A migration changes stored user data, not just Python declarations. Classify potential table locks, scan duration, index builds, and table rewrites using representative data size. Add explicit lock/statement timeouts where the deployment contract requires bounded impact.

For a rolling deployment, use an expand/contract sequence when needed:

1. Add a compatible shape that old and new versions can tolerate.
2. Deploy the writer/reader changes required for transition.
3. Backfill and verify data with an explicit progress/retry strategy.
4. Remove the old shape only after consumers and rollback requirements permit it.

A large data migration may require a dedicated resumable job instead of one long DDL transaction. PostgreSQL operations such as concurrent index creation have special transactional constraints; apply the supported Alembic mechanism and prove the exact migration path rather than copying a generic snippet.

Run migrations once through a deployment-owned job, not concurrently in every API/worker startup. Backups, restore rehearsal, maintenance windows, and operator approval for destructive changes belong to the deployment plan. An Alembic downgrade function alone does not establish recoverability of dropped data.

## Acceptance checks

1. On a fresh isolated PostgreSQL database, apply the complete history to the intended head and verify the actual owned tables/constraints.
2. Run metadata drift detection (`alembic check` for the selected supported version). Ensure all owned model mappings were loaded, or a false clean result can hide omitted tables.
3. Create a database at the previous supported revision, seed representative historical data, apply the upgrade, and verify both transformed data and preserved business invariants.
4. Exercise the deployed application's persistence path against the migrated schema. A migration command exiting zero does not prove the code can use the result.
5. If downgrade is promised, test it with data and then re-upgrade. Otherwise record forward-only behavior and the recovery procedure instead of adding a meaningless `pass` downgrade.
6. Check the intended revision graph, but use Alembic's metadata/API rather than a parallel custom revision model.
7. For lock/time/rolling-compatibility claims, test representative workload and concurrent old/new application behavior. A small fixture database establishes correctness, not production migration latency.
8. Isolate and clean only test-owned databases or schemas; preserve logs and failure exit status if cleanup also fails.

## Sources and limits

The inspected Vitok project declared `alembic>=1.19.1` in a migration group and contains [real migration integration tests](https://github.com/kleksar/vitok/blob/6dc2ad3f75dd3860973cde08ea68f955af7fc4e2/tests/integration/infra/postgres/test_migrations.py). Its project-specific numbered/legacy history policy is deliberately excluded from this recipe.

[Alembic documentation](https://alembic.sqlalchemy.org/en/latest/) is the upstream reference for the locked version; it was not fetched during this transfer. No migration or PostgreSQL process exists in the seed, so these commands and integration claims become verifiable only when a consuming feature implements them.
