# Schema pattern

## Start from a scenario

A schema expresses a real input, output or message contract. Introduce it when a consumer needs that contract, not to complete a symmetric `Create/Read/Update` family. Several related schemas can live in the owning `schemas.py`.

Before choosing a representation, define who owns the meaning, where input comes from, who consumes the result and which validation/serialization guarantees are needed. Internal structured values can use ordinary Python types; Pydantic is appropriate when runtime validation or serialization is an actual boundary requirement.

## Ownership

[Architecture contracts](../architecture/contracts.md#data-and-orm-placement) owns paths and separation between application DTOs, transport schemas and ORM mappings. The same fields do not necessarily mean the same contract:

- transport data may have aliases, pagination, wire encodings or public exposure limits;
- application data expresses a use case without HTTP/Telegram/worker details;
- persistence mappings express storage representation and constraints.

Do not make a SQLAlchemy model the public response or turn a request schema into the universal domain model. Conversely, do not copy identical DTOs between layers only to manufacture separation. Reuse is appropriate only when meaning, accepted values, disclosure and change lifecycle genuinely coincide.

## Required semantic decisions

For an input/output contract, define the applicable:

- required versus omitted versus nullable fields;
- accepted enum vocabulary, identifiers, units and timestamp interpretation;
- limits and ordering of collections;
- default values and whether defaulted values are validated;
- unknown-field and coercion policy;
- serialization and externally visible aliases;
- sensitive fields that must never be exposed;
- compatibility with existing callers, messages or stored representations.

Use names such as `Create` and `Update` only when those are actually distinct accepted operations. A generic `Update` model with all fields optional leaves meaning unresolved.

## Partial changes

For `PATCH` or another partial update, specify omitted fields, explicit null, empty collections, replacement versus merge, validation order and error behavior. Do not implement a generic `model_dump(exclude_unset=True)` merge until the owner has accepted what each supplied field means.

A nullable field is not automatically clearable. A list is not automatically appended, replaced or deduplicated. These are application decisions, not Pydantic defaults. Concurrent updates may also require a version/precondition contract at the service and repo boundaries.

## Validation and conversion

[Pydantic conventions](../conventions/pydantic.md) owns field types, validators and model APIs. Pure model-local validation belongs in the schema; I/O, authorization, stateful rules and cross-entity decisions belong in the service/application owner.

Map external representations deliberately at their adapter. Do not normalize values, discard fields or coerce identifiers merely to fit a convenient DTO. Treat a serialized message that survives releases as a public contract with compatibility needs, not as an arbitrary function argument dump.

## Evidence

Tests cover accepted/rejected values and the observable serialized shape where it matters. Include omitted/null/default distinctions, bounds and sensitive-field exclusion. Test the actual source entry API: direct Python construction, HTTP JSON and environment strings can have different parsing behavior.

Schema tests prove data behavior, not uniqueness, commit, authorization or successful external execution. Those claims stay with their owning service and integration tests.
