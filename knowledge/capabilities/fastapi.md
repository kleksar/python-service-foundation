# FastAPI

## Applicability and ownership

Apply this recipe when a feature needs an HTTP API or webhook receiver. Do not add an HTTP server merely to make the seed look runnable; a CLI, polling bot, or worker may not need one.

This document owns FastAPI integration choices. [Entrypoints](../architecture/entrypoints.md), [schemas](../patterns/schemas.md), [errors](../patterns/errors.md), and [settings](../conventions/settings.md) own their reusable contracts. A recipe is not evidence that FastAPI is installed.

Before implementation, establish the caller, request/response contract, authentication and authorization boundary, expected concurrency, maximum request size, time budget, and deployment process. Decide whether the API must keep serving when a particular dependency fails. An API without authentication is appropriate only when its explicitly accepted exposure permits it.

## Add only the required pieces

For an async ASGI API, a starting dependency selection is:

```sh
uv add fastapi 'uvicorn[standard]'
```

Add `pydantic` explicitly if application code imports it, and `pydantic-settings` only when configuration models are required. Add HTTPX and an async pytest integration only with tests that use them. Resolve and commit the lockfile; this recipe does not establish compatibility of every future release with the project's Python version.

Create files for actual responsibilities:

- `src/app/api/app.py`: side-effect-free application factory and router registration.
- `src/app/api/entrypoint.py`: process composition boundary exported to the ASGI server.
- `src/app/api/<feature>/router.py`: HTTP parsing, dependency acquisition, service invocation, and response mapping.
- `src/app/api/<feature>/schemas.py`: HTTP-specific DTOs, only when they differ from application contracts.
- `src/app/api/errors.py`: application-error-to-HTTP mapping, when there are errors to map.
- `src/app/<feature>/service.py`: business behavior, independent of FastAPI.

A separate `lifespan.py` or dependency module appears when its responsibility warrants a file, not because every API needs the same tree. Do not generate CRUD endpoints for absent use cases.

## Factory, resources, and request boundaries

Keep reusable factories and schema imports declarative. The executable composition boundary may construct the framework's required exported object; it must not perform network I/O while importing it. Create network clients, pools, and background resource managers in lifespan/startup, inject them explicitly, and close them on shutdown. Partially failed startup must close resources already opened; an exit stack is useful for this exact responsibility.

Share process-safe clients and connection pools, not request transactions. Each request or application operation acquires its own persistence context according to [transactions](../patterns/transaction.md). Do not put an `AsyncSession` into global application state or pass a request session to a task that can outlive the request.

Use `Depends` at the HTTP boundary, not inside business services. The service should also be callable from a job or a bot without constructing a fake request. Keep blocking I/O off the event loop; declaring a blocking function `async` does not make it non-blocking.

When adding a route, specify:

- Input validation, omitted/null behavior, and output serialization.
- Status codes for success and named expected failures.
- Whether retries can duplicate a side effect; use [idempotency](../patterns/idempotency.md) where relevant.
- Pagination limits and a stable ordering when collections are exposed.
- Authentication versus resource-level authorization; possession of an identifier is not permission.

A request ID is correlation data, not proof of identity. Validate or replace untrusted correlation headers. Do not reflect exception text, SQL, settings, or secrets into error responses.

## Health and operational behavior

Add health endpoints only when a deployment or operator consumes them:

- Liveness answers whether the process can respond, without querying downstream services.
- Readiness checks only dependencies required to accept the promised traffic. It uses bounded timeouts and returns an unavailable response, typically HTTP 503, for expected dependency outages.
- A dependency omitted from the project does not leave a no-op readiness probe behind.

A database check must cover failures while obtaining a connection as well as executing the query. Classify real driver/OS/SQLAlchemy operational failures at the adapter boundary; do not catch every exception to hide programming errors. Avoid logging an identical warning on every polling probe without an intentional sampling/transition policy.

Configure trusted proxies, allowed hosts, CORS, request limits, and TLS termination according to the actual ingress. Do not enable broad proxy trust or credentialed wildcard origins as a default. Durable work belongs in a separately managed execution path; FastAPI in-process background tasks are not a durable queue.

## Acceptance checks

The new feature needs behavior tests plus integration evidence appropriate to the claim:

1. Instantiate the factory without credentials or network access when those are not yet needed. Verify startup/shutdown explicitly; an in-process ASGI HTTPX transport does not by itself run lifespan.
2. Exercise one real route through the application, including validation, expected errors, authorization denial where applicable, and response schema/headers. Use dependency overrides only for the boundary intentionally excluded from that test.
3. For a DB-backed route, test the service-to-real-database path separately or through the route; a fake repo does not establish persistence correctness.
4. Start the actual ASGI server in a subprocess for process/network claims. After its readiness signal, send an HTTP request and terminate it with the normal shutdown signal. Verify cleanup and exit status.
5. If dependency-aware readiness is promised, make the dependency unavailable and verify readiness failure without liveness failure. Verify recovery when the contract permits it.
6. Check that response bodies and captured logs do not disclose supplied secrets or internal exception data.

After adding the entrypoint, the ordinary launch command is:

```sh
uv run uvicorn app.api.entrypoint:app --host 127.0.0.1 --port 8000
```

Use public binding only in the deployment configuration that requires it. Production process settings are not development reload settings.

## Sources and limits

The factory/entrypoint pattern was inspected in [Vitok API code](https://github.com/kleksar/vitok/tree/6dc2ad3f75dd3860973cde08ea68f955af7fc4e2/src/vitok/api). Its project declared `fastapi>=0.141.1` and `uvicorn[standard]>=0.52.3`; these are source constraints, not this seed's dependencies or a claim of fresh validation. The earlier foundation baseline at commit `a9e97bd` supplied the liveness/readiness distinction; its import-time database engine is deliberately not the lifecycle recommended here.

[FastAPI documentation](https://fastapi.tiangolo.com/) and [Uvicorn settings](https://www.uvicorn.org/settings/) are upstream references to check against the locked versions when implementing. They were not fetched for this transfer. No HTTP runtime is executed by the seed's documentation gate.
