# Settings and environment configuration

Applies when a component has a real configurable responsibility. An external service, a neighboring `settings.py` or an example recipe does not by itself require a Settings model, an environment key or a profile.

## Ownership and declaration

The component that interprets a value owns its name, type, default, validation and allowed sources. Place its model in an owner-local `settings.py`; use Pydantic Settings when a typed environment adapter is needed. Do not start with a universal settings object importing every future integration.

Static route names, constants and fixed protocol choices do not become environment inputs for symmetry. Operational timeouts, pool limits and feature-specific endpoints become fields only where they are genuinely configurable. Validate finite values and accepted relationships between timing/size limits in the settings model rather than repeating hidden bounds in consumers.

Settings declarations are reusable and import-safe. Creating settings validates configuration only; it does not open a connection or prove service availability. Instance/resource creation belongs to [the composition root](../architecture/entrypoints.md), which passes explicit dependencies without ambient fallback settings.

## Sources and precedence

Choose and document sources for each owner. With ordinary Pydantic Settings v2 sources and no custom CLI source, precedence is initialization arguments, process environment, dotenv, file secrets, then defaults. Custom sources or ordering change observable behavior and need focused tests; do not assume the default after customizing it.

Use a clear owner prefix, such as `POSTGRES_`, to avoid accidental overlap. Explicit aliases and external vendor names are mappings to document, not a second naming scheme discovered by guesswork. A source may parse environment strings before model validation; test source parsing separately from strict direct construction.

A local dotenv file is optional unless the contract explicitly requires it. Missing credentials still fail when required; do not invent development defaults for production secrets. Absence of a local profile does not mean an empty value and must not make tests depend on a developer's private files.

Examples of suitable future paths are `env/postgres.env` for an ignored local profile and `env/postgres.env.example` for tracked documentation. Do not create them before that settings owner exists. A project's deployment system may inject process environment or file secrets without a dotenv profile.

## Defaults and examples

The model is the single owner of defaults. A tracked example documents canonical keys and safe values; it is not an automatic runtime fallback or a second set of defaults. Label required inputs clearly without real credentials. If an example is intended to be executable by tooling, define and test its parsing, placeholders and precedence explicitly.

Do not automatically copy examples over local profiles. Do not load arbitrary developer profiles in CI. CI supplies its own isolated values, including ephemeral service addresses, rather than inheriting local secrets or ports.

In Pydantic Settings v2, defaults are normally validated; verify this on the pinned version. For ordinary Pydantic models follow [Pydantic conventions](pydantic.md). Required, nullable, omitted and empty-string inputs are different. Do not add `env_ignore_empty` or silently coerce an empty credential to missing without an accepted contract.

## Secret inputs and diagnostics

Use appropriate secret-aware field types when they help representation, but do not treat them as a complete secrecy boundary. Raw input can appear in validation errors before it has become a secret type; custom validators and parsers can also expose values. `hide_input_in_errors` alone does not protect every diagnostic representation.

Apply [security](security.md) at source ingestion and diagnostic output. Test expected textual secret inputs on accepted and rejected paths. Extract a secret only at the narrow adapter call that needs it; never use its value in an error message, log field or default serialization. Do not build an arbitrary-object redaction framework to compensate for logging unreviewed objects.

## Verification

Use owner-local tests for defaults, missing required values, unknown inputs, invalid values, declared precedence and no network I/O. Test environment parsing and direct construction separately. Assert private local profiles are not required for import or a clean baseline.

Use pytest monkeypatch to isolate only keys owned by the settings models exercised by a test and restore them afterwards. Preserve unrelated environment such as proxy configuration; do not clear the whole process environment or install a collection-time global sanitizer.

For an executable example, check key inventory and semantic default equality against the model. For secret-bearing settings, inspect `repr`, validation output, dumps and logs on relevant failure paths. Upstream API reference: [Pydantic Settings documentation](https://docs.pydantic.dev/latest/concepts/pydantic_settings/); exact APIs and source behavior must be checked for the consuming project's locked version.
