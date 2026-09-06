# Redis

## Applicability and decisions

Apply when a concrete feature requires shared caching, coordination, rate-limit state, expiring interaction state, or a selected queue/result backend. “We may need Redis later” is not sufficient. A process-local cache can be enough when its loss, isolation, and staleness are acceptable.

This document owns Redis client integration and storage-specific decisions. [Taskiq](taskiq.md) owns its broker/result use; [idempotency](../patterns/idempotency.md), [errors](../patterns/errors.md), [settings](../conventions/settings.md), and [security](../conventions/security.md) own reusable application boundaries.

Specify the role before choosing a topology:

| Role | Decisions that change implementation |
| --- | --- |
| Cache | Key composition, TTL, invalidation, maximum staleness, stampede behavior, whether misses/outages may fall back |
| Rate limiting | Atomic algorithm, scope, time source, fail-open/fail-closed policy |
| Conversation/session state | Ownership, expiry, restart loss, concurrency, sensitive fields |
| Coordination/lock | Lease duration, ownership token, renewal, fencing, behavior after lease loss |
| Broker/result storage | Delivery, persistence, retention, eviction, acknowledgement and recovery contract from the queue owner |

A Redis deployment optimized for an evictable cache may be unsuitable for a durable queue. Logical database numbers or key prefixes provide namespacing, not security or resource isolation.

## Dependencies and placement

For direct async Redis calls:

```sh
uv add redis
```

Add the dependency explicitly if code imports it even when a framework also depends on it. A framework-owned backend may own its own client; do not add an extra generic Redis client that no application code uses.

Place actual shared client construction in `src/app/infra/redis/client.py`, settings in `settings.py` only if needed, and role-specific operations near their real owner. A business feature should not receive arbitrary raw key access merely because a Redis client is available; expose the narrow operation it needs.

Construct clients/pools in the composition root, configure connect/socket timeouts and connection limits, and close owned resources on shutdown. Client factory creation is not proof of network connectivity. If a caller injects a shared pool, define who closes it and test that ownership; do not close another consumer's pool accidentally.

Choose bytes versus decoded text responses deliberately. Use a versioned, bounded serialization format for stored application data. Do not deserialize untrusted Redis data with pickle. Stored state can outlive a deployment, so schema compatibility and invalidation are part of the contract.

## Keys, TTL, atomicity, and topology

Use stable role/feature prefixes and include all dimensions that distinguish values, especially tenant/user scope. Do not place secrets or unbounded user strings in key names. Prefer opaque bounded identifiers for sensitive dimensions.

Set expiry with the write atomically where the command supports it; a separate write then `EXPIRE` can leave an immortal key after a crash. Define whether updating a value refreshes or preserves expiry. Use server-side atomic operations, transactions, or a narrowly scoped script for read-modify-write semantics; pipelining alone only batches commands.

Pick the supported topology explicitly: standalone, managed primary/replica, Sentinel, or Cluster. Redis Cluster supports only database zero, and multi-key operations/scripts may require all keys in one hash slot. Do not copy a fixed DB allocation such as `0..3` from another project. Cross-slot layout and replica-read consistency are integration decisions to test against the actual deployment.

For a cache, specify bounded fallback and load-shedding behavior. A database fallback during a Redis outage can overload the database; fail-open is not automatically safe. Avoid a blanket TTL policy that silently turns business state into disposable cache data.

For locks, a lease timeout does not prevent an old holder from continuing work. Use an ownership token for release/renewal, and use fencing at the protected resource when the correctness claim requires exclusion after lease expiry. A Redis lock is not automatically a substitute for a database constraint or transactional state machine.

Persisted/queued state needs an explicit Redis persistence and eviction policy. Replication/failover durability and acknowledged-write loss depend on the chosen service and settings; do not advertise “durable” based solely on an API call returning success.

## Failure and security boundary

Classify timeouts, connection failures, serialization failures, and expected missing/expired keys separately. Implement the role's stated degradation policy; silently ignoring all Redis errors can violate rate limits, authorization state, or duplicate prevention.

Use private networking, authentication/ACLs, and TLS as required by the deployment. A logical DB number is not an access-control boundary. Keep credentials out of Redis URLs in logs and prevent command/value dumps containing user data.

Avoid `KEYS *`, `FLUSHDB`, and `FLUSHALL` in application or shared-test cleanup. For test-owned prefixes, maintain owned key identifiers or use a bounded scan strategy; cleanup must never assume that an entire Redis instance belongs to a single test unless it actually created and exclusively owns that instance.

## Acceptance checks

1. Exercise the selected commands and serialization against the real Redis version/topology. A fake Redis library does not prove Cluster, scripts, expiry, or network semantics.
2. Test missing, expired, malformed, and old-format values according to the contract. Use bounded eventual checks for real TTL behavior rather than exact wall-clock equality.
3. Test atomic concurrent updates and duplicate attempts where correctness depends on them.
4. Interrupt connectivity and verify the declared fallback/fail-closed behavior, bounded latency, and resource cleanup.
5. Give concurrent tests unique namespaces; verify cleanup removes only their own keys. Test a neighboring key survives.
6. If using Cluster, run the actual multi-key/script cases there. Standalone success is not evidence of Cluster compatibility.
7. For lock claims, simulate expiry and a stale owner; for persistence/failover claims, use the actual topology and recovery scenario. A `PING` cannot establish either claim.
8. For Taskiq-owned state, run the worker/result tests in the [Taskiq recipe](taskiq.md), not just direct Redis client tests.

## Sources and limits

Inspected [Vitok Redis client](https://github.com/kleksar/vitok/blob/6dc2ad3f75dd3860973cde08ea68f955af7fc4e2/src/vitok/infra/redis/client.py) and its Taskiq integration. Vitok declared `redis>=8.1.0` and allocated logical DBs by role. This recipe transfers client ownership and role separation, but deliberately rejects that allocation as a universal default.

[redis-py documentation](https://redis.readthedocs.io/) and [Redis documentation](https://redis.io/docs/latest/) are upstream references to verify for the locked versions; they were not fetched here. No Redis dependency, server, or runtime guarantee is present in the seed.
