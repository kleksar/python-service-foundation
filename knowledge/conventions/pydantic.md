# Pydantic conventions

Applies when a real validation/serialization contract introduces Pydantic v2. Pydantic is not a dependency of the empty seed. [Schemas](../patterns/schemas.md) owns scenario meaning and placement; this document owns how a selected model expresses and verifies that meaning.

## Define the field contract first

For each field, identify accepted source input, the Python value after validation, consumers and any public serialization. The annotation describes the post-validation value, not every raw representation that a parser may accept.

Choose the most precise standard-library or Pydantic type that matches those semantics. Do not automatically replace `str` with a URL/email type, `int` with a strict constrained type or a credential with an arbitrary length limit. Those choices can reject valid input or introduce normalization not accepted by the owner.

Use `Annotated` with `Field` or appropriate Pydantic metadata for a genuinely reusable constraint. Keep one-off field bounds and defaults next to the field. Prefer these forms to dynamic constrained factories. A new alias needs independent semantic meaning; an alias that only renames `PositiveInt` is unnecessary.

## Required, omitted, nullable and default

These are separate decisions:

| Declaration shape | Meaning |
| --- | --- |
| `value: T` | Required, rejects `None` unless `T` itself permits it |
| `value: T | None` | Required, accepts `None` |
| `value: T | None = None` | May be omitted; missing input becomes `None` |

Use assignment-form `Field(...)` for model-local defaults, factories, aliases and metadata. A default factory creates a default value; it does not establish that the value was supplied by a caller. For partial updates, distinguish omitted fields from explicitly supplied nulls using the accepted update contract and model field-set information, not truthiness or a generic merge helper.

Pydantic v2 `BaseModel` defaults are not validated by default. Enable default validation where the owner requires it and test the behavior. `BaseSettings` has its own defaults behavior; see [settings](settings.md).

## Model configuration is a decision

Choose strictness, unknown-field handling, aliases, mutation and serialization according to the input boundary. There is no universal `strict=True`, `extra="forbid"`, `frozen=True` base for every model. Strict Python construction and JSON/environment parsing can have different accepted representations; test the actual entry API rather than assuming they are interchangeable.

A frozen model prevents field reassignment, not mutation of a nested `list` or `dict`. Use immutable value types when deep immutability is part of the contract. Do not declare a model immutable while handing out mutable collections that change its meaning.

Reject non-finite numeric values when the semantic contract requires finite amounts, durations or measurements. Bound collections and strings when an input/resource limit is meaningful. Validation must not invent a business rule solely to make a field look constrained.

## Validators

Use this order: a precise type, field metadata, then a custom validator when neither can express the accepted rule.

- An after field validator consumes and returns the declared field type.
- A before validator handles the actual raw-input contract and must not assume input is already a string or dictionary.
- A model validator handles a pure relation between fields.
- Validators do not perform database queries, HTTP calls, resource acquisition, authorization, cross-entity checks or lifecycle transitions.

Normalization is behavior: trimming, case-folding, timezone conversion or silently dropping unknown data needs an accepted contract. A validator must not quietly change a value's type or meaning merely to make another component accept it.

## Serialization and trust

Use `model_validate` for the intended Python-object boundary and the matching JSON API for JSON input. Choose `model_dump(mode="json")` when a consumer needs JSON-compatible values, and `model_dump_json()` only when that boundary needs an encoded JSON string. Do not double-encode a DTO inside another JSON envelope.

An ORM object's compatibility with `from_attributes` is not permission to expose all its fields. Build the declared application/transport contract explicitly at the owning adapter. A full model dump is not automatically safe for a response or log; follow [security](security.md) and [logging](logging.md).

## Focused evidence

Cover accepted and rejected boundaries, the actual Python type, omitted versus explicit `None`, defaults, aliases, collection behavior, inter-field relations and public serialization as applicable. Test one reusable type thoroughly at its owner and its composition in each distinct consumer without duplicating the entire matrix.

For framework or settings integration, test the entry path the runtime really uses. A passing direct-construction test does not prove HTTP JSON coercion or environment source precedence. Upstream API reference: [Pydantic v2 documentation](https://docs.pydantic.dev/latest/); verify APIs against the version selected in the consuming project's lockfile.
