# Testing conventions

## Test the claim at its boundary

[Development](../governance/development.md) owns RED → GREEN → refactor. This document owns test placement, isolation and selection of evidence.

| Claim | Suitable primary evidence |
| --- | --- |
| Pure application behavior | Unit test through the public service/contract |
| Validation and serialization | Focused model tests using the real input API |
| Adapter query, commit/rollback or constraint | Integration test against the real database |
| Framework binding or response mapping | Application/transport integration test |
| Process startup, shutdown, signals or worker delivery | Real subprocess/runtime test |
| Installed package correctness | Build and import outside the source tree |
| Local knowledge navigation | Documentation link/anchor check |
| Safe business/security semantics | Focused behavior checks plus inspection of the affected boundary |

A mock is useful for an owned unit-test seam; it does not establish SQL behavior, durable delivery, network reachability or framework lifecycle. Evidence is valid only for its revision, environment and relevant assumptions.

## Grow the test layout with code

The seed has only its real package and knowledge tests. When a project acquires enough responsibilities, organize `tests/unit/<owner>/`, `tests/integration/<owner>/` and `tests/e2e/<outcome>/` as needed. Do not create empty levels or copy the entire source tree into tests by habit.

Unit tests isolate one coherent owner. Integration tests follow a real boundary, such as Postgres or the HTTP application. E2E tests follow an observable user/business scenario, not every private helper. Put shared fixtures in the nearest relevant `conftest.py`; a root fixture should actually apply across its consumers.

## Deterministic unit tests

Use explicit dependency injection, small behaviorally truthful fakes, clocks and bounded random inputs where needed. Prefer real lightweight value objects over mocks of every internal function. Assert outcomes and public interactions rather than incidental helper order or source formatting.

Cover important boundaries and failure paths, not only a happy example. A rejected operation should also prove the absence of unintended state changes when that is its contract. Parametrize a coherent input matrix; do not hide distinct business scenarios behind a large generic test framework.

Do not rely on network access, a developer's dotenv, global mutable state or test execution order. Monkeypatch only owned environment keys and let the fixture restore them. Async fixtures follow the lifetime of the event loop and resource they actually own; add pytest-asyncio only when async tests exist.

## Real integration isolation

Each test run owns its database/schema/queue/key namespace, ports and processes. Prefer unique identifiers, ephemeral ports and readiness probes with bounded deadlines. Poll a concrete condition rather than guessing readiness through a fixed delay.

Clean up only resources the test created. Never use `FLUSHALL`, delete a shared database or terminate an unrelated process to make integration tests deterministic. Preserve the original failure and exit status when cleanup also fails, and provide safe diagnostics that do not disclose credentials.

Run migrations through their actual entrypoint when migration behavior is the claim. Run a real worker when retry/ack/redelivery is the claim. An in-process HTTP client can prove binding, but a process/network test is needed for import strings, packaging, listener behavior or shutdown guarantees.

Infrastructure tests may be explicitly opt-in locally, but their absence must be visible and the relevant CI lane must execute them when the feature promises those guarantees. A skipped integration suite is not a green integration result.

## Gate discipline

Run the smallest focused tests during editing. Before handoff, run the candidate checks covering the changed contracts and the repository quality gate. Keep local and CI commands aligned; [the foundation specification](../specs/foundation.md) owns the baseline commands, and capability recipes add only checks for installed capabilities.

Do not weaken a check or add broad skips solely to make the gate green. If an environment cannot run a required boundary, report the missing evidence. Re-run only checks invalidated by a later change rather than treating every documentation edit as a need to repeat every integration runtime.

Coverage numbers can reveal untested paths but do not prove useful assertions or correctness. Add coverage tooling when a real consumer needs its feedback; do not invent a universal percentage as the definition of quality for an empty seed.
