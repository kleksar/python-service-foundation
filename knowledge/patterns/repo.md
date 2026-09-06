# Repo pattern

## The persistence boundary

A repo expresses the persistence operations needed by one business module. Introduce it when a use case actually needs storage; do not create a repo because a schema or table exists in an example.

`app/<feature>/repo.py` owns the application-facing contract, normally a small `Protocol` when a technology adapter implements it. `app/infra/<technology>/<feature>/repo.py` owns the concrete implementation. This is one semantic repo across a port/adapter boundary, as defined by [layout](../architecture/layout.md#singular-service-and-repo), not two business repos.

The application port knows standard/application types, not SQLAlchemy, driver sessions, SQL query objects or `infra`. A concrete adapter implements the port directly; a second Gateway or RepositoryService layer is not required.

## Operations follow use cases

Expose operations with accepted meaning, not a generic CRUD surface. Define applicable details:

- how identity and missing data are represented;
- whether an operation inserts, replaces, partially updates or conditionally transitions;
- duplicate/uniqueness behavior under concurrent callers;
- ordering, pagination and limits;
- whether reads need locking or a consistent snapshot;
- the materialized result returned to the application.

Do not expose arbitrary query/filter dictionaries, raw SQL fragments or a generic `save` that hides incompatible create/update semantics. Add the next operation when a real consumer needs it. Avoid one repo per database table when several tables implement one coherent storage responsibility.

## Adapter responsibilities

The adapter owns database queries, parameter binding, persistence representation and mapping to the application contract. It does not decide business authorization or scenario-specific state transitions simply because those decisions can be expressed in SQL.

Some application invariants require atomic SQL operations or database constraints. The application owner defines their meaning; the adapter implements the atomic mechanism and tests it against real storage. A prior `exists` check is not sufficient uniqueness protection under concurrency.

Do not return session-bound ORM objects or rely on lazy loading after the adapter call. Return declared application values or receipts. Avoid silently truncating results, swallowing constraint errors or converting every driver exception into a missing row.

Commit, rollback and session lifetime follow [transaction](transaction.md). Error translation follows [errors](errors.md): translate only the named expected condition for which the adapter owns a contract, not every integrity or connection failure into a generic application outcome.

## Avoid false generality

There is no seed `BaseRepo`, universal filtering language, reusable CRUD mixin or adapter registry. A shared abstraction requires an actual common contract and a consumer, not several methods with similar signatures.

If another independent repo is needed inside a feature, review the feature decomposition. Keep one semantic repo per module rather than collecting unrelated repos under `repos/`. An in-memory test fake and PostgreSQL implementation of the same contract remain valid multiple implementations.

## Evidence

A small fake supports service unit tests, but adapter behavior needs real integration evidence. Cover relevant mapping, missing/duplicate results, ordering, limits, constraints, transaction participation and concurrency. Prove that results are usable after the owning session closes when that is the output contract.

The [Postgres recipe](../capabilities/postgres.md) supplies technology-specific integration checks. Adding a test double does not demonstrate that the SQL adapter or migration works.
