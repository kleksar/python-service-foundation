# HTTP client

## Applicability and ownership

Apply when a feature calls a remote HTTP service. Prefer HTTPX for an async Python caller; choose its synchronous client when the caller is intentionally synchronous. Do not introduce an async runtime solely to make one synchronous script use an async client.

This recipe owns connection, transport, and remote-response handling. [Errors](../patterns/errors.md), [schemas](../patterns/schemas.md), [settings](../conventions/settings.md), [security](../conventions/security.md), and [idempotency](../patterns/idempotency.md) own the corresponding application contracts.

Resolve these inputs before implementing:

- The upstream contract, authentication scheme, payload/response limits, and expected status codes.
- Whether destinations are fixed trusted endpoints or may be influenced by users.
- Latency budget, concurrency, pool capacity, rate limits, and retry safety.
- What a timeout means for a remote side effect, and how an ambiguous outcome is reconciled.
- Which response fields become application data and which must never be logged.

## Integration shape

```sh
uv add httpx
```

Add settings/validation libraries only when imported by the implementation. Commit the resolved lockfile. The source project used HTTPX's 0.28 API family; recheck constructor and transport behavior when changing the selected version.

Use `src/app/infra/<provider>/client.py` for a provider-specific adapter. Create `src/app/infra/http/client.py` only when multiple consumers have a genuinely shared transport policy. A universal HTTP abstraction is not required for one integration.

The composition root owns the client context and injects the adapter into the feature service. Reuse a long-lived client/pool within its event loop, instead of constructing one for each request. Close it on shutdown, including after failed startup. Keep provider DTO mapping within that provider's boundary; business code should not consume arbitrary HTTPX responses.

Configure connect, read, write, and pool-acquisition timeouts explicitly. HTTPX phase timeouts are not a total end-to-end deadline: add a bounded operation deadline when the product contract requires one, including retry delays. Size connection pools together with caller concurrency so the timeout policy does not hide unbounded queues.

Illustrative lifecycle fragment, to adapt and test in the consuming project:

```python
import httpx


def create_http_client() -> httpx.AsyncClient:
    return httpx.AsyncClient(
        timeout=httpx.Timeout(connect=3.0, read=10.0, write=10.0, pool=2.0),
        limits=httpx.Limits(max_connections=20, max_keepalive_connections=10),
        follow_redirects=False,
    )
```

The numeric limits above are examples, not foundation defaults. The caller must own `async with create_http_client() as client:` or equivalent cleanup. Do not add a Settings class merely to make every number configurable.

## Responses and retries

Distinguish transport failure, HTTP failure, invalid content type/encoding, malformed payload, and a valid upstream business rejection. Translate only the expected failures owned by the adapter; retain causal information internally without exposing credentials or response bodies indiscriminately.

Validate response size and schema before allowing upstream data into business logic. Streaming responses must be closed on every path. For large or untrusted bodies, limit bytes while reading the stream; checking `Content-Length` alone does not bound an actual response.

Retry only a classified transient failure under a replay-safe contract:

- A bodyless GET/HEAD is a common conservative starting case, not proof that every upstream has safe semantics.
- A POST may have succeeded before the connection failed. Retry only with a provider-supported idempotency mechanism or explicit duplicate tolerance.
- Replaying streaming request bodies requires a replayable body source.
- Bound attempts and elapsed time; respect `Retry-After` only within the accepted operation budget. When it exceeds the budget, surface/defer the operation rather than retrying earlier than requested.
- Use backoff with jitter where multiple clients can synchronize. Do not multiply retries in transport, adapter, service, and job layers.
- Close discarded responses before waiting/retrying, or the pool can be exhausted by the retry mechanism itself.
- Cancellation is not an upstream failure to catch and retry.

A generic retry wrapper is not part of the seed. Add one only when a concrete integration needs and tests it. Circuit breakers likewise require an availability contract and observable state, not a checkbox.

## Network and secret boundaries

For a fixed provider, construct paths under a validated base URL; do not accept arbitrary absolute URLs in a helper that forwards provider credentials. Redirect behavior must not broaden trust accidentally.

For user-controlled destinations, address SSRF explicitly: allowed schemes/hosts/ports, DNS resolution and private/link-local/loopback destinations, redirects, proxy behavior, and network egress controls. A textual hostname allowlist alone does not prevent DNS rebinding. Verify TLS; do not disable it to make an integration test pass. Decide whether environment proxy settings are permitted, rather than assuming the host environment is harmless.

Do not log authorization headers, cookies, token-bearing URLs, raw query strings, or full bodies by default. Provider error text can contain sensitive request data. Attach safe provider/operation/status/attempt/duration fields instead.

## Acceptance checks

1. Use controlled transport tests for response mapping, malformed payloads, expected status codes, retry selection/budgets, cancellation, and close behavior. Inject the clock/backoff wait where appropriate; tests should not wait real retry intervals.
2. Verify that non-replay-safe operations are not automatically retried after ambiguous failures.
3. Exercise an actual local HTTP server for connection, streaming, read timeout, redirect, and pool/lifecycle claims. A mock transport does not prove socket behavior.
4. Test response-size enforcement while streaming, not just declared headers.
5. If arbitrary destinations are allowed, test rejected schemes, private addresses, redirect escape, and credential forwarding boundaries under the actual resolver/network design.
6. For provider compatibility, use an explicitly authorized sandbox or recorded sanitized contract fixture with its limits stated. No paid/live side-effect call is implicit in this recipe.
7. Assert safe logs for invalid upstream payloads and token-bearing request failures.

## Sources and limits

Inspected [Vitok HTTP client](https://github.com/kleksar/vitok/blob/6dc2ad3f75dd3860973cde08ea68f955af7fc4e2/src/vitok/infra/http/client.py) and [retry adapter](https://github.com/kleksar/vitok/blob/6dc2ad3f75dd3860973cde08ea68f955af7fc4e2/src/vitok/infra/http/retry.py). Vitok declared `httpx>=0.28.1`. Its retry class is project-specific; the recipe intentionally transfers decisions and failure cases, not that class or its exact defaults.

[HTTPX documentation](https://www.python-httpx.org/) is an upstream reference to verify when implementing; it was not fetched here. The illustrative fragment and future integration acceptance checks are not executed by the seed documentation gate.
