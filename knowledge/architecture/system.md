# System architecture

## Purpose and growth model

This project is an ordinary Python seed, not a generator or a framework. The executable baseline is defined by [the foundation specification](../specs/foundation.md). Future technologies are described by conditional recipes; their presence in knowledge does not authorize unused production code.

Grow as a **feature-oriented modular monolith**, using package-by-feature and vertical slices. Group code by a business capability or coherent application responsibility before separating its technical roles. A global `services/`, `repos/`, `schemas/` or `routers/` tree spreads one feature across unrelated technical collections and is not the default architecture.

Components appear with a consumer in a current feature. Do not materialize the full example layout, a prerequisite platform, an unused health server, a sample domain or an optional integration because a future project might need it. A recipe can be comprehensive while `src/app/` remains small.

## Boundaries

| Boundary | Responsibility |
| --- | --- |
| `app/<feature>/` | Application use cases, domain meaning and owner-local contracts |
| `app/api/`, `app/bot/`, `app/jobs/` | Existing external interfaces and their transport adaptation |
| `app/infra/<technology>/` | Concrete external technology adapters and resource mechanics |
| A named process composition root | Binding concrete dependencies and owning their runtime lifecycle |

These are permissible forms, not mandatory directories. A command-only utility need not contain API, bot, jobs or infra packages. A small integration may remain a module until it needs an independent package boundary.

## Dependency direction

- Transport adapters call public application interfaces. They do not implement business decisions or SQL.
- Application services, application schemas and repo/UoW ports do not import transports, frameworks, ORM models, database drivers or `infra`.
- Infrastructure implements application contracts without owning product rules. It may translate vendor representations into the owner's input/output contract.
- Composition roots depend on both application contracts and concrete adapters in order to wire them. Application code never imports the root back.
- Cross-feature calls use explicit public application contracts and form an acyclic graph. A feature does not reach into another feature's repo or private helper.
- A feature-local ORM mapping is an isolated persistence declaration, not permission for its application service to depend on SQLAlchemy. Its allowed placement is defined by [contracts](contracts.md).

An annotation is still an architectural dependency. Deferred evaluation, a string annotation, dynamic import or `TYPE_CHECKING` cannot justify a dependency direction that would otherwise be invalid.

## Shared responsibilities

Keep types and helpers with their semantic owner. Extract a shared responsibility only when current consumers need the same owner-independent contract, not merely similarly shaped objects. Give it a precise name and tests for that contract.

Do not start with `common/`, `core/` or `utils/` as an unowned collection. A real cross-cutting capability such as logging can acquire a clearly named owner when used. Shared persistence lifecycle infrastructure can follow demonstrated transaction needs; it is not a mandatory seed module.

Do not introduce generic `BaseService`, `BaseRepo`, CRUD mixins, policy mixins, a plugin registry or a custom dependency-injection framework without a concrete common contract that direct composition cannot express simply. Repetition of a few explicit calls is cheaper than a false abstraction.

## Choose the next owner

- File names, decomposition and singular service/repo rules: [layout](layout.md).
- Public data, compatibility and ORM placement: [contracts](contracts.md).
- Process and transport wiring: [entrypoints](entrypoints.md).
- Application orchestration: [service](../patterns/service.md).
- Persistence and transaction semantics: [repo](../patterns/repo.md) and [transaction](../patterns/transaction.md).
- Behavior evidence: [testing](../conventions/testing.md).

These rules adapt the feature-oriented and canonical-owner approach used in Vitok. Its product modules, fixed infrastructure topology and historical exceptions are not part of this project.
