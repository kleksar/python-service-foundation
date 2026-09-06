# Python conventions

These are defaults for new and changed Python code. They govern expression, not product behavior. The configured Ruff formatter/linter is the mechanical authority; do not maintain a competing manual formatting checklist.

## Imports and public names

Use absolute imports from defining modules. Do not use wildcard imports, package-facade re-exports or import-time registration to hide ownership. A required dependency belongs in project metadata; catching `ImportError` to turn an undeclared integration into an optional feature is not the seed's architecture.

Keep dependency direction valid for annotations as well as execution. Do not introduce `TYPE_CHECKING`, quoted annotations or dynamic imports merely to hide a cycle. Refactor the owner or introduce a justified narrow port. Do not add `from __future__ import annotations` routinely on the supported Python version; use it only for a concrete evaluation/compatibility need.

Use a leading underscore for module-private helpers. Public functions and types expose an intentional contract rather than every internal convenience. Give identifiers their domain or operational meaning; `data`, `manager`, `helper` and `utils` are not substitutes for an owner. File and service/repo naming belong to [layout](../architecture/layout.md).

## Straightforward implementation

Prefer guard clauses and small coherent operations to deep nesting. Separate completed logical phases with whitespace without fragmenting a single operation. Comments explain a non-obvious invariant or reason, not a line-by-line translation of code.

Use standard-library types when they express the contract. A dataclass can represent ordinary internal structured data; Pydantic is introduced for a real runtime validation/serialization boundary, not because all objects need a model base. Do not create marker wrappers or aliases that merely rename a builtin without adding a meaningful contract. See [typing](typing.md) and [Pydantic](pydantic.md).

Avoid mutable default arguments, shared mutable module state and function defaults that acquire resources. Do not derive operational defaults in multiple consumers. Configuration defaults belong to [settings](settings.md).

Treat time, randomness and external I/O as explicit inputs/dependencies when tests or business semantics need control. Use timezone-aware datetimes for instants and choose UTC/storage serialization at the owning contract. Use `Decimal` or integer minor units for monetary arithmetic when exactness is required; a float is not automatically a money type.

## Async discipline

Choose async for an I/O path and its libraries, not as a universal style. A standalone outer root uses `asyncio.run`; a framework-owned root uses the framework runner. Never create a nested loop in a request or task handler or mutate global loop policy to hide an incompatibility.

Do not run blocking network/file-heavy work on the event loop. Choose a supported async API, an explicitly bounded thread offload or a separate worker according to workload and cancellation semantics. Unbounded `gather`, fire-and-forget tasks and infinite queues are not concurrency strategies: establish limits, task ownership and failure propagation.

Cancellation is control flow. Cleanup uses context managers or `finally`; do not swallow cancellation or turn it into a retryable business failure. [Entrypoints](../architecture/entrypoints.md) owns acquisition and shutdown.

## Exceptions and diagnostics

Catch the narrow expected types that a boundary knows how to handle. Do not catch `BaseException` or blanket `Exception` in ordinary application code to return success, hide bugs or update state that can be initialized safely before the operation. A true process/framework last-resort handler needs an explicit contract, preserved failure semantics and safe diagnostics; it is not a reusable service pattern.

Use `raise ... from error` for a justified translation when the cause is safe to retain internally. Do not expose raw third-party exception text to clients. [Errors](../patterns/errors.md) owns semantic categories; [logging](logging.md) owns event content and level.

## Verification

Run Ruff and the configured strict type checker, then focused behavior tests. Static tools do not establish semantic ownership, safe logging or correct transaction boundaries; inspect those claims directly. Avoid broad suppressions to make a mechanically green result out of unclear code.
