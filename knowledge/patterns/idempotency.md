# Idempotency and retry pattern

## Decide what a duplicate means

Idempotency is a property of an operation under a defined identity and retention window, not a worker library setting. Apply this pattern when an HTTP retry, webhook replay, scheduled run, message redelivery or ambiguous external failure can repeat a meaningful effect.

Specify:

- what identifies the same logical operation;
- which caller/tenant owns that identity;
- whether a changed payload with the same key is rejected;
- how concurrent duplicates are resolved;
- what result or status a replay returns;
- retention and behavior after expiry;
- recovery from an in-progress or unknown outcome.

Do not add a generic idempotency table or Redis lock to the seed. A naturally idempotent state assignment may need no new mechanism. A payment, message or append-only action may require a durable operation record and provider-supported key.

## Durable and atomic state

A check-then-insert in separate transactions is not duplicate protection under concurrency. Use an atomic operation or storage constraint that matches the accepted key scope. Keep a result/status record with enough information to distinguish completed, rejected and still-unknown work when the contract needs replay.

A payload fingerprint helps detect conflicting reuse only if serialization, relevant fields and confidentiality are defined. Do not hash arbitrary object `repr` or assume a hash makes sensitive payload data harmless.

TTL/expiry changes semantics: after expiry a repeated request may execute again. Choose retention from the business retry/replay window, not an unexplained library default. Deleting a deduplication key is a state transition with consequences, not routine cache cleanup.

## Retries

Retry only identified transient failures with a bounded attempt/time budget and an explicit backoff policy. Respect provider limits and cancellation. Retrying permanent validation or authorization failures wastes resources and can amplify incidents.

Before retrying, determine whether the previous attempt could have committed or caused a remote effect. A timeout or disconnected response does not prove failure. Use an idempotency key accepted by the remote system, query status, or reconcile rather than blindly repeating an operation whose outcome is unknown.

A local transaction cannot roll back a remote API call or broker publish. Follow [transaction](transaction.md) for dual-write consistency. An outbox makes the local publication intent durable; it does not automatically make a consumer's external effect exactly-once.

## Worker delivery

A worker's ack, result-save and retry behavior must be established on the selected broker/backend/version. At-least-once delivery means handlers may run again, including after an effect succeeded but acknowledgment failed. Result storage alone is not a business deduplication ledger.

Define poison-message handling, retry exhaustion and operator recovery for the actual task. Scheduler locks or leader election prevent only the duplication they actually cover; lease expiry can permit overlapping workers. Do not equate a Redis lock with an exactly-once business guarantee.

The [Taskiq recipe](../capabilities/taskiq.md) describes worker-level checks. It does not select application idempotency semantics on behalf of a feature.

## Evidence

Exercise first execution, sequential replay, conflicting payload, concurrent duplicates, expiry, failure before and after the durable effect, and recovery of ambiguous/in-progress state as applicable. Use real storage and worker/process boundaries for atomicity and redelivery claims.

Verify that a duplicate returns the accepted result without repeating the prohibited effect. Include the relevant crash window, not only two sequential calls in one healthy process. Report guarantees narrowly: tested replay behavior under a particular setup is not proof of universal exactly-once execution.
