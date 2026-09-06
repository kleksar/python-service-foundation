# Knowledge and document lifecycle

## One owner for each norm

A reader must be able to recover the current contract from the repository without an agent transcript. [The index](../INDEX.md) inventories current owners. An accepted rule is written once, in its narrowest suitable owner; consumers link to it instead of copying another version.

| Document family | Owns | Does not establish |
| --- | --- | --- |
| Architecture, conventions and patterns | Durable structural and engineering rules | Product-specific behavior by implication |
| Capabilities | Conditional integration recipes | A claim that the capability is installed or tested here |
| Specifications | Accepted intended behavior of this system | A queue of speculative features |
| Plans | Dependency ordering, coordination, handoff or recovery | Requirements or permanent policy |
| Archive | Explicitly superseded or withdrawn history | Current instructions |
| Supporting research | Question, sources, facts and limitations | A decision merely because research recommends it |

Use the existing canonical owner whenever possible. A new document needs an independent responsibility, not a new filename for the same rule. Register every new current owner in the index in the same change. Exact project behavior takes precedence over a conditional example only when the accepted override and its owning contract are explicit; conflicting current norms must be reconciled, not silently ranked by convenience.

## Specifications remain current

A specification under `knowledge/specs/` contains accepted durable behavior and the checks needed to establish it. Follow [development](development.md) for its content. Intended behavior may be accepted before implementation; clearly state a partial implementation or migration boundary rather than pretending a contract proves runtime availability.

**Implementation completion does not archive a specification.** A working feature still needs its contract. Revise the owner when the intended behavior changes; move it to `knowledge/archive/specs/` only when it is replaced or withdrawn and retaining history has value. Identify the non-normative status and successor, or explicitly state that no successor exists. Git already preserves ordinary edits; archive is not a requirement to duplicate all old versions.

When a foundation copy becomes a client project, reassess the scope of the foundation specification. Keep applicable engineering rules, add product contracts, and replace or retire only seed-specific guarantees that no longer describe the accepted system. Do not leave contradictory current specifications merely to preserve lineage.

## Plans are disposable coordination

Use session-local tasks by default. Retain a plan only when dependency order, multiple contributors, several sessions or recovery has a concrete consumer.

A retained plan contains links to canonical requirements, the bounded scope, ordered dependencies and enough handoff state to resume. It does not copy the specification, routine progress, full test output or a second set of acceptance requirements. Plans do not grant permissions or impose new mandatory review rounds.

Paths express retained plan state:

- `knowledge/plans/active/<topic>.md`: a current coordination consumer exists;
- `knowledge/plans/completed/<topic>.md`: completed coordination retained for independent historical value;
- `knowledge/plans/abandoned/<topic>.md`: stopped work retained with its reason and remaining boundary.

Use a short explicit `Status: active`, `Status: completed` or `Status: abandoned` matching the path. A date prefix is useful when separate efforts would otherwise collide; it is not a mandatory naming grammar. Create directories only with real documents.

When coordination is no longer needed, the plan may be removed. Retaining it as completed or abandoned is optional, not a completion gate. On a retained move, update status and relative links. Unfinished work remains unfinished in history; never mark a checkbox complete to make the archive look tidy. Durable decisions must already live with their canonical owners.

## Verification and maintainability

Use ordinary relative Markdown links and stable, descriptive headings. Local documentation checks validate their supported link/anchor syntax; they cannot prove semantic ownership, freshness of external sources or completeness of a recipe.

For a document change, review:

- whether this is the right existing owner;
- whether readers can discover it through the index;
- whether an example is clearly distinguished from a current requirement;
- whether code claims match the implementation being described;
- whether moved documents leave stale links or competing current rules;
- whether source/version limitations remain explicit.

Do not build elaborate document parsers to enforce product-specific historical conventions in a generic seed. Add a narrow structural check only for a real, recurring failure with a deterministic oracle.
