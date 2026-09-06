# Service pattern

## When a service exists

A service owns a coherent application capability: it coordinates the steps required to fulfil a use case and applies its business decisions. Add it with a real scenario, not a transport skeleton or a generic CRUD convention.

The singular filename and one-service-per-module rule belong to [layout](../architecture/layout.md#singular-service-and-repo). One service can contain several related operations. Stateless operations can be functions; an object is useful when it encapsulates a real shared dependency/lifecycle boundary. A class that merely stores arguments to call one function is not automatically an improvement.

## Responsibilities

A service:

- accepts an application input contract and explicit dependencies/context;
- makes the scenario's business decisions and state transitions;
- calls the feature's repo or other public application contracts as needed;
- returns an application result or raises an expected owner-defined error;
- determines the use-case transaction boundary according to [transaction](transaction.md).

It does not parse HTTP requests, return FastAPI responses, depend on Telegram/Taskiq decorators, execute SQL or obtain clients from a global container. The adapter maps those concerns at their own boundary.

Pure value rules can remain small functions within the feature. Stateful or cross-entity checks belong to the application owner, not a Pydantic validator. Authorization decisions must use the caller context established by the accepted security contract; validation alone is not authorization.

## A useful interface

Name operations after the actual capability, such as submitting an order or reconciling a payment, rather than adding `create/read/update/delete` by habit. Specify whether a missing resource, duplicate request or invalid transition is an error, a no-op or a distinct result. Use the [schemas](schemas.md) and [errors](errors.md) owners for those semantics.

Inject only what the operation needs. A service requiring persistence can accept its feature-owned repo or UoW contract. A pure computation does not need a repo, UoW or settings object to match neighboring services. A caller should not have to construct the entire application to invoke one use case.

Application contracts must not expose ORM rows, framework requests, background task result handles or driver exceptions as normal outputs. Translate at the owning boundary and preserve the dependency direction in [system architecture](../architecture/system.md).

## Composition across features

Call another feature through its public application interface, never its repo or private model manipulation. The graph must stay acyclic. If two services mutually need one another, move orchestration to the actual higher-level owner or reconsider the feature boundary; do not resolve the cycle with dynamic imports.

Do not force unrelated operations into one service to obey singular naming. An independently evolving responsibility deserves a named module. Conversely, multiple steps in one scenario do not justify a package of one-function service classes.

External effects introduce failure and consistency decisions. Before adding retries, background dispatch or a second database, define the relevant [idempotency](idempotency.md) and transaction contract rather than making the service appear atomic through a broad exception handler.

## Evidence

Unit-test accepted outcomes, business rejection, dependency failures and observable state transitions through the public service interface. A fake repo can establish scenario orchestration if it faithfully models the contract. Use real storage/process evidence for promises about atomicity, concurrency or durable task delivery.

Test that rejected behavior does not perform prohibited downstream effects. Do not assert every private helper call or incidental statement order when only the public result matters.
