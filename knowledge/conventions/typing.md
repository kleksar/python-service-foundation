# Typing conventions

## Make boundaries precise

Use the project's strict Pyrefly configuration. Annotate public functions, service/repo contracts, injected dependencies and non-obvious state so callers can understand accepted input and result without reading an implementation. Tests are part of the checked code, not a general exception to type discipline.

Use modern supported Python syntax: builtin generics, `T | None`, and `type Name = ...` for a real alias. An alias belongs to its semantic owner; it must not conceal an invalid architectural dependency or merely rename `str`/`int` without a distinct contract.

Choose the narrow truthful type:

- `object` for an unknown value that must be inspected before use;
- `Mapping`/`Sequence` for a read-only consumer contract when concrete mutation is not needed;
- an exact result/schema type instead of an unstructured `dict[str, Any]` at an application boundary;
- an enum or `Literal` for a genuinely finite vocabulary;
- a callback type or small `Protocol` for a real injected behavior.

A protocol is justified by the consumer boundary, not by the number of implementations. A single PostgreSQL adapter can implement a feature-owned repo port to preserve dependency direction. Do not generate protocols for every internal helper or mirror an entire third-party library interface.

## Static types are not validation

Annotations describe the contract after validation; they do not validate external JSON, environment variables or messages. Establish input shape at the transport/source boundary and use [Pydantic](pydantic.md) where it is selected. Avoid propagating unvalidated `Any` into application code.

`typing.cast` changes the checker's view only. Use it after a real invariant has been established, with a local explanation when the proof is not obvious. Prefer narrowing with a truthful predicate or typed library API. A cast is not an alternative to parsing or runtime validation.

Do not use `assert` for rejecting untrusted user input: assertions may be disabled and express programmer invariants, not a stable public error contract.

## Escape hatches

A type suppression needs the smallest location, the diagnostic code where supported, and a concrete reason such as an incomplete third-party stub. Keep the actual runtime boundary covered by a focused test. Prefer a small typed adapter over repeating `Any`, casts or suppressions throughout services.

Do not disable strictness for an entire application package, accept untyped public functions or replace the checker because one integration is inconvenient. When the chosen library cannot meet a needed typed contract, make the limitation and adapter ownership explicit.

Annotations must respect [dependency direction](../architecture/system.md). Type-only imports or postponed evaluation cannot legitimize application code referring to ORM or transport internals. Library-specific requirements for runtime annotation introspection must be tested where the framework consumes those annotations.

## Verification

Run `uv run pyrefly check` after changing a checked signature, annotation, protocol, dependency or stub. Type checks prove static consistency, not data validity, concurrency safety or correct runtime framework registration. Use the corresponding model, adapter or process test for those claims.

When changing Python or checker versions, resolve the lockfile deliberately and verify the same code on the configured interpreter. The current seed supports one Python minor; it does not claim compatibility with every ecosystem package.
