# Development entrypoint

## Start with the changed responsibility

Read [the index](../INDEX.md), choose the task route, and open only its relevant canonical owners and named dependencies. Read the current specification before changing intended behavior. A broad knowledge corpus is not a startup reading list; neither archive nor plans are a fallback source of current requirements.

The [foundation contract](../specs/foundation.md) distinguishes the executable seed from future capabilities. Do not add a dependency, runtime module or configuration simply because a recipe describes it. A new feature activates only the rules it actually needs.

## Authority and ownership

Repository knowledge supplies subject-matter contracts, constraints and verification requirements. The user or host controls task orchestration and permissions. This repository does not install another lifecycle-controller, require a personal agent roster, or depend on user-scoped skills, memory, MCP servers or absolute local paths.

Use [document lifecycle](document-lifecycle.md) to locate and change the canonical owner. Code and tests provide evidence about implementation; they do not silently override accepted requirements. Agent memory and discussion are supporting context, not a second policy store. If current owners conflict or code differs from intended behavior, identify the conflict and resolve the affected contract rather than choosing the convenient source.

A local skill, if one is introduced for a recurring task, is an operator: it links to canonical rules, does the bounded work and returns. It does not copy the rules, choose a model roster or trigger a separate chain of process stages.

## Work and evidence

Follow [development](development.md) for specification-driven changes and TDD. Use [testing](../conventions/testing.md) to select checks for the changed boundary. Run focused checks while editing and the applicable candidate gate before handing off. Report failed, unavailable or skipped checks as such; do not present inspection or a historical green run as fresh runtime evidence.

Keep changes within the requested boundary. Read a target before replacing or removing it, preserve unrelated local work, and avoid expanding a small feature into a reusable framework. The architecture examples describe permissible growth, not files to pre-create.

## Safety and integration

Apply [security](../conventions/security.md) to secrets and external effects. Do not put credentials, client payloads, private local profiles or machine-specific configuration into tracked files or diagnostic output.

A request to inspect does not authorize edits; permission to edit does not by itself authorize publishing, deploying or destructive cleanup. Follow the user's actual authorization for commit, push, PR, merge and external actions. No standing integration permission is embedded in copied knowledge.

When work is complete, report the changed behavior, checks actually run and remaining limitations. Persist accepted durable decisions with their canonical owner, not in an agent transcript or mandatory completion journal.
