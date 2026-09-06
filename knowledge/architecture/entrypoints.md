# Entrypoints and resource lifetime

## Transport versus composition

A transport adapter translates an external event into an application call and translates its result back. It owns protocol binding, not domain decisions, persistence queries or delivery guarantees of another layer.

A composition root chooses concrete dependencies and owns a process boundary. Direct construction and explicit arguments are the default. A framework's dependency mechanism may adapt those objects to requests; it is not a reason to introduce a project-wide service locator or DI framework.

| Real interface | Typical owner |
| --- | --- |
| HTTP resource | `app/api/<resource>/router.py` |
| Telegram scenario | `app/bot/<scenario>/` or one coherent module |
| Background process/task adapter | `app/jobs/<process>.py` |
| Application factory | Owner-local `app.py` or another precise factory module |
| Framework import-string root | Owner-local `entrypoint.py` |
| Named CLI command | Owner-local `command.py` |

These files do not exist until an interface needs them. `entrypoints/<name>.py` is justified only when there are multiple independent roots; a single root stays singular.

## Declarative reusable modules

Importing settings declarations, factories, repo adapters or task definitions must not load environment-dependent settings, connect to a service, configure global logging or start a worker. Tests and callers must be able to import these declarations under unrelated or absent environment settings.

Some frameworks require a module-level `app`, broker or scheduler for an import string. Only the explicit framework composition root may perform the required assembly on import. Resource acquisition still belongs to the framework's startup/lifespan hooks when available. Reusable factories receive settings or already created dependencies rather than reading globals.

A `python -m` package can have a thin `__main__.py` that calls the real command under the executable guard. Parsing, composition, error presentation and shutdown belong to the defining role module, which tests can import directly. Avoid a generic `main.py` that mixes factories, models, handlers and process lifetime.

## Acquisition and release

A process creates each used settings owner once at startup, validates configuration without network I/O, then acquires long-lived clients in an explicit scope. Pass dependencies to consumers. The relevant [settings rules](../conventions/settings.md) own sources and defaults.

For every resource, name its owner and lifetime: process-level pool, request-level unit of work, task-level transaction or short-lived stream. Use context managers or `try/finally` so cleanup occurs on normal return, expected failure and cancellation. Acquire resources in an order that permits partial-startup cleanup; release them in reverse order. `contextlib.ExitStack` or `AsyncExitStack` is appropriate when several acquisitions form one real lifecycle, not as speculative infrastructure.

Do not keep a SQL session in a process-global object or share one across concurrent requests/tasks. Do not create a fresh HTTP client or engine for every call when a scoped shared client is the actual contract. The relevant capability recipe specifies resource APIs and limits.

Shutdown must stop accepting new work, apply the chosen drain/cancellation policy, close owned resources and preserve a meaningful failure exit status. A health endpoint or successful import does not prove shutdown behavior; use a process-level check when that lifecycle is promised.

## Event loops and context

A standalone async process uses one runner at its outer boundary. Framework-owned roots delegate to the framework's loop; never call a second runner inside a handler. The Python-specific rules are in [Python conventions](../conventions/python.md).

Request/task correlation context must be created and cleared at the corresponding boundary. Avoid ambient mutable globals that can leak tenant identity, credentials, transaction state or request IDs between concurrent operations.

## Focused evidence

Test factory imports without valid external environment, explicit injection of a fake dependency, startup failure cleanup and normal shutdown. Exercise real framework/process startup when import strings, worker registration, signals or exit status are the claim. Transport tests separately establish request binding and error mapping; they do not replace the service's business tests.
