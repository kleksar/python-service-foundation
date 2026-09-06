# Knowledge index

`knowledge/` is the canonical home of engineering rules and accepted system contracts. Each rule has one physical owner. This index provides discovery, not a requirement to read every document. Start with the task route, read its owners and named dependencies, and consult history only for an explicit historical question.

## Task routes

| Task | Read first, then follow relevant links |
| --- | --- |
| Change or add a business capability | Architecture/system and layout; patterns/service; its current specification |
| Add or change an input/output contract | Patterns/schemas; conventions/pydantic when used |
| Persist data or change a transaction | Patterns/repo and transaction; capabilities/postgres and alembic |
| Add HTTP endpoints | Architecture/entrypoints; capabilities/fastapi; patterns/errors |
| Add a Telegram scenario | Capabilities/telegram; patterns/service |
| Call an external API | Capabilities/http-client; conventions/security and logging |
| Add durable background work | Capabilities/taskiq; patterns/idempotency; the selected broker recipe |
| Add configuration | Conventions/settings and security |
| Diagnose a failure | The affected specification and capability; conventions/testing and logging |
| Change development documents | Governance/document-lifecycle |
| Start a new project from this seed | Specs/foundation; architecture/system; the README |

Names in the route table refer to the linked owners below. A technology recipe is conditional guidance, not evidence that its runtime code or dependency exists.

## Governance owners

| Owner | Scope |
| --- | --- |
| [Agent entrypoint](governance/agent-entrypoint.md) | Selective loading, authority, safety and host boundary |
| [Development](governance/development.md) | Spec-driven changes, TDD and acceptance evidence |
| [Document lifecycle](governance/document-lifecycle.md) | Canonical ownership, specifications, plans and archive |

## Architecture owners

| Owner | Scope |
| --- | --- |
| [System](architecture/system.md) | Feature-oriented boundaries and dependency direction |
| [Layout](architecture/layout.md) | File/package growth, names and one service/repo per module |
| [Contracts](architecture/contracts.md) | Public ownership, data/ORM placement and compatibility decisions |
| [Entrypoints](architecture/entrypoints.md) | Transport responsibilities, composition and resource lifetime |

## Convention owners

| Owner | Scope |
| --- | --- |
| [Python](conventions/python.md) | Imports, expression, names and async discipline |
| [Typing](conventions/typing.md) | Static boundaries, protocols and justified type escape hatches |
| [Pydantic](conventions/pydantic.md) | Field/model composition and validation semantics |
| [Settings](conventions/settings.md) | Configuration ownership, sources, defaults and examples |
| [Logging](conventions/logging.md) | Event semantics, safe fields and failure logging ownership |
| [Testing](conventions/testing.md) | Test levels, isolation, fixtures and boundary evidence |
| [Security](conventions/security.md) | Secrets, trust boundaries, safe diagnostics and external effects |

## Pattern owners

| Owner | Scope |
| --- | --- |
| [Service](patterns/service.md) | Application use-case responsibility and orchestration |
| [Repo](patterns/repo.md) | Persistence ports, operation semantics and adapter mapping |
| [Schemas](patterns/schemas.md) | Scenario-first DTO ownership and input/output distinctions |
| [Errors](patterns/errors.md) | Expected outcomes, error translation and transport mapping |
| [Transaction](patterns/transaction.md) | Commit ownership, UoW and external side effects |
| [Idempotency](patterns/idempotency.md) | Duplicate delivery, keys, atomicity and retry contracts |

## Conditional capability owners

| Owner | Add only when |
| --- | --- |
| [FastAPI](capabilities/fastapi.md) | The project needs an HTTP application |
| [Telegram](capabilities/telegram.md) | A real bot scenario needs Telegram transport |
| [HTTP client](capabilities/http-client.md) | A feature calls an external HTTP service |
| [Postgres](capabilities/postgres.md) | A feature needs relational persistence |
| [Alembic](capabilities/alembic.md) | The application owns versioned relational schema changes |
| [Redis](capabilities/redis.md) | A specified cache, coordination or messaging role needs Redis |
| [Taskiq](capabilities/taskiq.md) | Work must run through a separately managed background runtime |
| [Docker](capabilities/docker.md) | An executable service needs container packaging or local infrastructure |
| [Observability](capabilities/observability.md) | An operating service needs health, metrics, tracing or error reporting |

## Current specifications

| Owner | Scope |
| --- | --- |
| [Foundation](specs/foundation.md) | The minimal executable seed and its verification guarantees |

New accepted specifications are registered here in the same change. Existing contracts remain current after implementation. Plans and archive are not current normative owners; their meaning is defined by document lifecycle. Do not create empty directories for future documents.
