# Transaction pattern

## Name the atomic boundary

A business use case owns the decision about which durable changes must succeed together. The repo owns persistence operations; infrastructure owns session/connection mechanics. Do not infer transaction semantics from a convenient framework dependency or decorator.

Before adding a transaction, identify writes, reads requiring consistency, expected conflicts, external effects and the observable result. A pure computation or a read-only call does not need a generic UoW merely to resemble a neighboring feature.

## Commit and rollback ownership

The application service chooses when a use-case transaction commits. Repo operations do not commit independently; they participate in the caller's transaction. They may flush when needed to establish a storage result or constraint while preserving that boundary.

A resource scope that exits without a successful explicit commit rolls back pending work and releases its resources. Normal return from a context manager is not an implicit business decision to commit. Define what a failed commit means for the particular adapter: connection loss during commit may leave the outcome unknown, not reliably rolled back.

Do not hold a database transaction open across slow external HTTP calls or user interaction without a justified contract. Lock duration, deadlocks and pool exhaustion are operational consequences, not merely performance style issues.

## When a UoW is useful

Introduce a feature-owned `unit_of_work.py` contract when a scenario needs explicit coordination of repo operations and transaction lifecycle. The application sees only its repo and accepted lifecycle methods; concrete SQLAlchemy behavior stays in `infra/postgres`.

A useful UoW defines:

- how it is created and entered;
- when its repo becomes usable;
- explicit commit and its failure semantics;
- rollback/release without successful commit;
- whether reuse, nested entry or repeated commit is invalid;
- session ownership under concurrent requests/tasks.

Prefer one operation-scoped, one-shot instance when that matches the scenario. Do not share a live session/UoW across concurrent operations or store it in a process-global service. A shared generic lifecycle base appears only after a real common contract needs it; the seed contains none.

## Concurrency and consistency

A read-then-write check is not an atomic constraint. Choose the actual mechanism for an accepted invariant: a database unique constraint, conditional update, version check, lock or suitable transaction isolation. The repo adapter implements it; the business owner defines its meaning.

Test concurrent conflict behavior on real storage. Do not claim serializability or exactly-once execution from one successful unit test. Retry serialization/deadlock failures only under a bounded policy and when re-running the complete operation is safe.

## External effects and dual writes

A database commit and an HTTP call or broker publish are not one atomic transaction. Sending before commit can expose rolled-back data; sending after commit can fail after durable state changed. State the required behavior before choosing a mechanism.

If the feature requires durable eventual publication, an outbox can record the event intent in the same local transaction and dispatch later with [idempotent handling](idempotency.md). Add it only for that real reliability requirement, not as mandatory infrastructure. The dispatcher still needs failure, ordering, retry and retention contracts.

A failed or timed-out call may have succeeded remotely. Never repeat an externally visible effect solely because the local caller did not receive success. A reconciliation path or operation key may be needed.

## Evidence

Use real database tests for commit, rollback, failed commit handling, constraints, concurrent conflicts and session cleanup. Check partial startup/acquisition failures where the adapter owns several resources. Use a fake UoW for service orchestration tests, but do not use it as proof of actual SQL atomicity.

The [Postgres](../capabilities/postgres.md) and [Alembic](../capabilities/alembic.md) recipes add the technology-specific checks once persistence exists.
