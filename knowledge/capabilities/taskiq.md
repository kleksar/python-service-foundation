# Taskiq

## Applicability and required contract

Apply when a feature needs work outside the caller's process or request lifetime: background processing, retries, independently scaled execution, or scheduling. Do not add a worker because an operation is `async`. A short bounded operation may remain synchronous from the caller's perspective; a disposable local task does not automatically need a durable queue.

This recipe owns Taskiq integration. [Service](../patterns/service.md), [transactions](../patterns/transaction.md), [idempotency](../patterns/idempotency.md), [errors](../patterns/errors.md), and [Redis](redis.md) own their reusable boundaries.

Accept the delivery contract before picking the broker:

- When submission is considered accepted and what happens if its outcome is ambiguous.
- Expected delivery behavior, duplicate tolerance, acknowledgement timing, and recovery after worker death.
- Execution timeout, shutdown grace, reclaim/visibility timeout, retryable failures, attempt budget, and poison-message handling.
- Whether anyone consumes results, how results/errors serialize, and result retention.
- Whether schedules are static or persisted and who owns scheduler execution.
- Monitoring and operator actions for backlog, failed work, stale pending messages, and expired results.

Do not claim exactly-once execution. Broker delivery, application effect deduplication, result persistence, and remote side effects are distinct contracts.

## Dependencies and responsibilities

For a selected Redis-backed Taskiq deployment:

```sh
uv add taskiq taskiq-redis
```

Choose Redis only if it fits the accepted delivery and operations contract. Add `redis` explicitly when application code directly imports it. Select a list/stream/other broker based on tested semantics, not the shortest constructor. Add a result backend or scheduler only if there is an actual consumer.

Typical files after choosing the capability:

- `src/app/infra/taskiq/broker.py`: broker/result-backend factories for the accepted topology.
- `src/app/infra/taskiq/settings.py`: real queue/runtime configuration, when needed.
- `src/app/jobs/entrypoint.py`: framework composition/export and deterministic task registration.
- `src/app/jobs/<feature>.py`: task adapters invoking the feature's `service.py`.
- A scheduler entrypoint only when scheduling has a separate executable responsibility.

Factories must not construct framework instances as a side effect of reusable module import. Taskiq CLI requires an exported broker in the executable entrypoint; that module is the deliberate composition boundary, not a general application dependency. Ensure task decorators register against the intended broker instance without circular imports or a second hidden broker.

Task inputs are bounded serializable application data, usually stable identifiers and a contract version when long-lived messages need it. Do not enqueue ORM objects, sessions, clients, secrets, or framework request objects. Large payloads belong in a suitable store with a reference and retention contract, not in an unbounded queue message.

The task adapter acquires fresh dependencies/persistence context and invokes the same business service used by other transports. It is not a second service layer. Producer and worker resources have distinct lifetimes; explicitly start/stop the producer-side broker resources as required by the locked Taskiq integration.

## Delivery, transactions, and failure cases

Publishing a task and committing a database transaction are not atomic merely because both happen in one function:

- Publishing before commit can let a worker observe missing data or execute work for a transaction that later rolls back.
- Publishing after commit can lose the handoff if the process dies in between.
- If the feature requires reliable DB-to-queue handoff, implement a transactional outbox or another explicitly justified protocol under [idempotency](../patterns/idempotency.md). Do not create an outbox without that requirement.

A result backend stores execution outcomes; it is not automatically an application audit log or proof that a business transaction committed. Decide what happens when the business effect succeeds but result saving fails. Retrying may repeat the effect unless its application operation is idempotent.

Check the broker's actual acknowledgement point and failure semantics on the locked version. For a result-dependent contract, inspect whether acknowledgement can occur after a failed result save. For streams, specify how pending messages are reclaimed, whether acknowledged entries are retained/deleted, and how queue retention affects other consumers. Do not blindly delete entries from a shared stream.

If the stock broker cannot meet a named requirement, first narrow the requirement or select a suitable backend. A custom broker subclass is an exception requiring a bounded compatibility contract and failure-injection tests, not the default copied from Vitok.

Retry transient infrastructure failures with a bounded policy. Validation failures, unsupported message versions, and permanent business rejection require a terminal or quarantine policy rather than an infinite loop. Preserve the original job/business identifier across retries and distinguish an execution attempt from the logical operation.

Relate execution limits, reclaim timeout, and graceful shutdown so a legitimately running task is not reclaimed prematurely. Socket timeout must allow the broker's blocking read plus an intentional margin; units must be explicit. Long-running jobs may require a heartbeat or another strategy supported by the chosen backend. These values are workload decisions, not universal constants.

## Scheduling and operation

Start the worker only after its required dependencies and task registrations are ready. Start the scheduler as a separate owned process when used; duplicated scheduler instances may duplicate dispatch unless coordination is explicitly supported and tested.

Define schedule identifiers, time zone, daylight-saving behavior, overdue/missed execution policy, update/delete concurrency, and persistence. A scheduler selecting a due item is not proof that the broker accepted it. Ensure schedule changes and dispatch failures have a defined recovery path.

After choosing and implementing the corresponding exported objects, typical CLI shapes are:

```sh
uv run taskiq worker app.jobs.entrypoint:broker
uv run taskiq scheduler app.jobs.entrypoint:scheduler
```

The scheduler command is applicable only if that object actually exists. Confirm CLI options, task discovery, concurrency, and shutdown behavior against the locked version and record the exact production invocation in the consuming project. Do not use development reload in production.

## Acceptance checks

1. Test task input validation and task-to-service mapping without a broker; test business idempotency at its actual persistence boundary.
2. Launch a real broker and a separate worker process. Submit a task, observe the promised business effect, and retrieve a result only if result storage is part of the contract.
3. Publish before worker startup and verify backlog behavior. Restart the worker and verify pending/recovery behavior for the selected broker, not a generic “restart succeeds” assertion.
4. Terminate a worker during execution and test reclaim/redelivery, bounded duplicates, and cleanup. Use uniquely owned queues/consumer groups and a test that can establish the claimed state transition.
5. Inject a failure after a business effect but before acknowledgement/result persistence. Verify the accepted effect/result/duplicate semantics.
6. Test timeout, permanent rejection, exhausted transient retries, and poison-message handling. Failed work must remain observable according to the contract.
7. If results are required, test serialization, expiration, and backend unavailability; specifically check the result-save/ack ordering on the locked implementation.
8. If schedules are required, test persisted schedules across scheduler restart, duplicate scheduler policy, changes/deletes, and a failed dispatch near its acceptance boundary.
9. For shutdown claims, signal the actual worker process and verify its grace/timeout behavior. Direct function tests cannot establish process lifecycle.

## Sources and limits

Inspected [Vitok broker implementation](https://github.com/kleksar/vitok/blob/6dc2ad3f75dd3860973cde08ea68f955af7fc4e2/src/vitok/infra/taskiq/broker.py), [settings](https://github.com/kleksar/vitok/blob/6dc2ad3f75dd3860973cde08ea68f955af7fc4e2/src/vitok/infra/taskiq/settings.py), and the existing [reliability tests](https://github.com/kleksar/vitok/blob/6dc2ad3f75dd3860973cde08ea68f955af7fc4e2/tests/integration/infra/taskiq/test_reliability.py). Vitok declared `taskiq>=0.12.4` and `taskiq-redis>=1.2.3`.

Vitok uses custom result-saving and stream-ack/deletion behavior. Its guarantees cannot be attributed to stock Taskiq or transferred to another version by copying a constructor. This recipe deliberately does not install those subclasses.

Upstream references: [Taskiq documentation](https://taskiq-python.github.io/) and [taskiq-redis](https://github.com/taskiq-python/taskiq-redis). They were not fetched during this transfer. No worker, Redis process, or delivery failure test runs in the seed's CI; those proofs belong to the feature that adds the capability.
