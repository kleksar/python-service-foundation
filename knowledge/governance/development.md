# Development through contracts and tests

This document owns the engineering obligations of a change. It is not a second orchestration workflow: the user or host chooses the necessary ordering, executors and review process.

## Start from observable behavior

For a feature, establish who consumes it, what changes at its boundary, what is deliberately excluded and how acceptance can fail. Read the existing owner before adding a new document or abstraction. Use the relevant conditional capability recipe only after the requirement establishes its need.

A durable product, public API, persistence, security or architectural decision belongs in a current specification or an existing canonical owner. Its minimum content is:

- purpose and scope;
- owner and consumers;
- inputs, outputs and interfaces;
- successful, rejected and failure behavior;
- invariants and meaningful compatibility decisions;
- acceptance checks that could falsify the claimed behavior.

The document states intended behavior without requiring access to the original conversation. Record rationale only when it changes a future implementation or operational decision. A new endpoint need not have separate brief, design, ADR and specification files describing the same contract.

A regression fix to already specified behavior normally updates tests and code, not the specification. A documentation typo has no new product contract. [Document lifecycle](document-lifecycle.md) determines whether a durable document or coordination plan is needed.

## TDD for behavior

For new or changed observable behavior:

1. Add the smallest meaningful regression or acceptance test against the intended interface.
2. Run it and observe a failure for the relevant missing or wrong behavior, not an unrelated environment error.
3. Implement the smallest production change that satisfies that test and existing contracts.
4. Refactor with the relevant tests green, preserving the accepted boundary.

A mock asserting that a function was called is not sufficient evidence for a promised database transaction or worker retry. Select the matching level using [testing](../conventions/testing.md). Pure application behavior should be testable without launching infrastructure.

Configuration, documentation, generated lockfiles and mechanical changes use their direct oracle. Do not manufacture a fake RED for a file move or equate installing dependencies with behavior verification. Characterization tests can establish existing behavior during a refactor, but do not make accidental legacy behavior an accepted requirement.

## Implement one useful slice

Prefer a narrow end-to-end scenario over horizontal preparation of unused services, repos, tables and transports. Code appears only with a consumer in the current feature. Keep technology choices in adapters and preserve [dependency direction](../architecture/system.md).

A discovered abstraction is justified by a coherent repeated contract, not similar syntax. Do not create a registry, a base class, a generic CRUD layer or an optional module system to avoid writing a few direct calls.

## Evidence and handoff

During implementation, use focused checks. Before handoff, cover all affected acceptance claims with the appropriate gate; a failed check changes the next action, rather than becoming an ignored attachment. A result remains evidence only for its revision, environment and assumptions. Re-run checks invalidated by a later change, not every unrelated check automatically.

State what was tested, where a real boundary was exercised and what could not be run. Test results do not prove security judgment or ownership coherence; inspect those seams when the change touches them. A code review is not a substitute for a missing runtime test, and a runtime test is not proof that secrets are safe in every diagnostic path.

Update affected canonical owners in the same change. Keep current specifications current after implementation. Close disposable coordination according to [document lifecycle](document-lifecycle.md), without treating a completed plan or a copied terminal log as an additional delivery gate.
