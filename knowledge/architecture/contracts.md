# Public contracts and data boundaries

## Semantic ownership

A contract belongs to the component that interprets its meaning and is accountable for its behavior. Neither a library choice nor a transport automatically becomes the owner of an application concept.

A public operation specifies accepted input, output, expected failures and relevant state transitions. Storage/public/security changes also identify compatibility constraints and a boundary-crossing acceptance check. Consumers use the defining public interface; implementation details are not made public by convenience imports.

| Concern | Canonical detail owner |
| --- | --- |
| Application operation | [Service](../patterns/service.md) |
| Persistence operation | [Repo](../patterns/repo.md) |
| Input/output meaning | [Schemas](../patterns/schemas.md) |
| Expected failures and translations | [Errors](../patterns/errors.md) |
| Atomicity and commit ownership | [Transaction](../patterns/transaction.md) |
| Environment inputs and defaults | [Settings](../conventions/settings.md) |

This document owns placement and compatibility boundaries, not a second formulation of those patterns.

## Data and ORM placement

- `app/<feature>/schemas.py` owns application DTOs for real scenarios.
- A transport's owner-local `schemas.py` owns wire-specific requests, responses and parameters when their contract differs from application data.
- `app/<feature>/models.py` owns that feature's SQLAlchemy mappings when relational persistence is used.
- `app/infra/postgres/models.py` may own the shared SQLAlchemy declarative base and metadata when the first mappings need them.
- `app/infra/postgres/<feature>/repo.py` owns SQL operations and conversion between mappings and application DTOs.

Do not mix Pydantic DTOs, settings models and SQLAlchemy mappings in one module or use one universal model for transport, business logic and persistence. Do not duplicate identical schemas just to manufacture layers: sharing requires the same accepted meaning, validation, exposure and change lifecycle, not only matching fields.

Feature ORM declaration modules are intentionally isolated from application behavior. They may depend on the standard library, SQLAlchemy and the shared declarative base; they do not import the service, transport, settings or external clients. Express ordinary cross-table references through metadata/foreign keys without importing another feature's business code. A mapping relationship that genuinely needs another owner must have an explicit persistence contract and remain acyclic; it never permits bypassing the other feature's application interface.

Application services, schemas and ports do not import ORM mappings even though the files share a feature directory. Return materialized application values from adapters, not session-bound ORM instances whose lazy loading or mutation can leak storage behavior outside the adapter.

## Validation boundaries

Schema composition is governed by [Pydantic conventions](../conventions/pydantic.md) when that library is used. Pure model-local rules belong in the model. Stateful, cross-entity, authorization, lifecycle and scenario-specific merge decisions belong to the application owner.

The database is a persistence safety net, not a mechanical copy of every DTO validator. Enforce applicable primary keys, foreign keys, nullability and uniqueness. Add a named SQL `CHECK` when the invariant is valid for every stored row, expressible deterministically in SQL and important to preventing invalid durable state. Transport-specific input limits do not automatically become storage constraints.

Schema validation cannot establish authorization, freshness, uniqueness under concurrency or successful commit. Select the appropriate application and integration checks rather than treating validated input as a trusted action.

## Compatibility decisions

Before changing a public or persistent contract, identify actual consumers and deployment overlap. Decide the behavior of omitted fields, new enum values, pagination/order changes, retired inputs and previously stored data. Do not silently normalize a breaking change into a compatible-looking result.

For a new private one-off service, do not add API versions, migration compatibility layers or event schema registries without a real consumer. When an API, database or task message survives across releases, document the needed compatibility and rollout behavior in its specification. [Alembic](../capabilities/alembic.md) and [Taskiq](../capabilities/taskiq.md) describe technology-specific implementation checks, not universal compatibility guarantees.
