# Observability

## Applicability and ownership

Apply when a real process needs operational diagnosis, alerting, error reporting, or service-level measurement. Start with signals that answer actual operational questions; do not add logging wrappers, telemetry exporters, dashboards, or an SDK to an empty package.

This recipe owns integration of observability tooling and its lifecycle. [Logging](../conventions/logging.md) owns event naming, levels, exception ownership, and safe fields; [security](../conventions/security.md) owns sensitive-data boundaries; [errors](../patterns/errors.md) owns error semantics. Health behavior remains with the process capability, not a competing observability framework.

Establish the consumer and purpose of each signal:

- What behavior indicates success, failure, saturation, or a stuck workflow?
- Who investigates it, through which backend, and with what retention/access policy?
- Which dimensions are safe and bounded, and which data must never leave the service?
- What sampling/aggregation policy is acceptable, and what happens when telemetry fails?

## Smallest useful integration

For one Python process, standard-library logging can be sufficient. Introduce structured JSON formatting when the runtime/log collector consumes it. Add `structlog` only when its context/processing interface pays for an actual integration; do not maintain both a home-grown event framework and a library wrapper for the same job.

If error aggregation is required, choose a backend such as Sentry and its framework integration explicitly. If distributed traces or metrics are required, select the required OpenTelemetry/provider packages and exporter deliberately. These are separate capabilities within this recipe, not an instruction to install every SDK.

Dependency commands depend on the accepted backend. For example:

```sh
uv add structlog
uv add 'sentry-sdk[fastapi]'
```

Run only the command for a selected implementation; the second assumes a FastAPI service and a Sentry requirement. Keep SDK versions locked and check their supported framework/Python combinations. Metrics/tracing dependencies are intentionally not listed as a blanket bundle.

Place configuration/factories under a concrete owner such as `src/app/infra/logging/` or `src/app/infra/sentry/` when that responsibility warrants a package. Do not create a generic `observability` facade that every feature must import if standard logger APIs or one concrete SDK boundary suffice.

## Process lifecycle and context

Configure process logging once at the executable boundary, early enough to capture startup errors. Importing feature/schema modules must not read env, install handlers, initialize exporters, or capture events. Repeated factory construction in tests must not accumulate handlers or duplicate logs.

If an SDK must instrument a framework before app construction, initialize it at the deliberate process entrypoint; do not turn a reusable factory import into global initialization. Own shutdown/flush with a bounded deadline. Telemetry shutdown must not hang process termination indefinitely or replace an already failing application's exit status.

Choose how server/access logs enter the same output pipeline. Test the actual process command: configuring an application logger alone does not mean Uvicorn or worker logs use that formatter. Avoid duplicate handlers through logger propagation and duplicate SDK exception capture at multiple boundaries.

Use request/job correlation context with scoped cleanup. Context from one concurrent request must not leak into another. At a queue boundary, propagate only the accepted trace/correlation fields, not a whole request context containing credentials. Incoming identifiers and tracing headers are untrusted metadata; validate limits before forwarding or logging them.

## Useful signals and bounded data

For HTTP, common useful signals are request count, duration distribution, status class, in-flight work, and saturation. Use route templates rather than raw paths as metric dimensions. User IDs, order IDs, arbitrary URLs, exception text, and unique request IDs are not acceptable high-cardinality metric labels by default.

For persistence, observe timeout/error rate and pool pressure when those affect service behavior. Do not log SQL parameters or entire ORM/Pydantic objects to obtain context. For background work, distinguish logical jobs from attempts; monitor backlog age, execution latency, retries, terminal failures, and stuck pending work according to [Taskiq](taskiq.md).

Error reporting should capture unexpected failures or explicitly selected operational failures once at their owning boundary. Expected validation/authorization outcomes do not automatically deserve exception events. A domain error can become a safe API response without exposing its internal cause.

Sanitize before events leave the process. JSON formatting does not remove secrets; `SecretStr` and SDK default scrubbing are not complete guarantees. Scrutinize exception messages, local variables, breadcrumbs, URL queries, headers, request/response bodies, and SDK automatic integrations. Treat exported telemetry as disclosure to another system, with its own access and retention policy.

Define sampling and drop/backpressure behavior. Telemetry failure should not generally fail a business request, but an audit trail with durability requirements is not ordinary best-effort telemetry and needs a separate accepted persistence contract.

## Acceptance checks

1. Capture representative log records and verify structured event fields, levels, timestamp/exception formatting, and stable output shape according to [logging](../conventions/logging.md).
2. Configure the process twice in a controlled test and verify the intended idempotency or explicit rejection, with no duplicate handlers/events.
3. Run the real API/worker entrypoint and inspect application plus framework logs; assert one coherent JSON line per event when that format is promised.
4. Trigger one expected and one unexpected failure through the actual boundary. Check response safety and exactly the intended number of captures/logs, not just that “something was logged.”
5. Supply sentinel secrets in settings, headers, payloads, URLs, and exception causes. Verify they are absent from rendered logs and controlled exporter payloads, including SDK-added metadata.
6. Run concurrent requests/jobs and assert scoped correlation does not leak. Check queue propagation separately where used.
7. Simulate unavailable/full exporters and verify the accepted business impact, bounded buffering, and bounded shutdown.
8. Validate metric label cardinality and trace sampling against representative workload when those guarantees matter. A unit test of a formatter cannot establish an operational SLO.
9. A real backend delivery test requires an explicitly authorized sandbox/project; a controlled in-memory transport proves payload construction, not network delivery or backend retention.

## Sources and limits

The inspected Vitok project declared `structlog>=26.1.0` and `sentry-sdk[fastapi]>=2.68.1,<3`; its [API entrypoint](https://github.com/kleksar/vitok/blob/6dc2ad3f75dd3860973cde08ea68f955af7fc4e2/src/vitok/api/entrypoint.py) makes logging/Sentry process initialization explicit. Its product-specific capture policy and integration facade are not seed defaults.

Upstream references: [Python logging](https://docs.python.org/3/library/logging.html), [structlog documentation](https://www.structlog.org/en/stable/), [Sentry Python](https://docs.sentry.io/platforms/python/), and [OpenTelemetry Python](https://opentelemetry.io/docs/languages/python/). They were not fetched during this transfer. No telemetry is exported by this seed, and recipe examples do not establish backend compatibility or safe capture without the consuming project's tests.
