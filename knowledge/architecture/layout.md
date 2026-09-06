# Layout and decomposition

## Name the owner before the role

The stable import package is `app`; distribution metadata can be renamed when copying the seed without rewriting every Python import. Under it, choose the business or operational owner first, then introduce role files only as that responsibility appears.

An illustrative feature with persistence could eventually contain:

```text
src/app/orders/
├── service.py
├── repo.py
├── schemas.py
├── errors.py
├── models.py
└── unit_of_work.py
```

This is not a scaffold or a completeness checklist. A feature without storage has no repo, models or UoW. A feature with no application errors has no `errors.py`. A coherent module may remain one file until its responsibilities require separation. Add `__init__.py` for a real regular package, not to reserve future directories.

## Singular service and repo

Each business module has **one semantic application service and one semantic repo at most**:

- use `service.py`, never a feature-level `services/` collection;
- use `repo.py`, not `repos.py`, `repositories.py` or `repository.py`;
- related operations may live in the same service or repo contract;
- a service may be functions or one object; a mandatory `Service` class adds no value by itself;
- `schemas.py` and `errors.py` may hold several related data/error types;
- knowledge uses the same singular names: `service.md` and `repo.md`.

The port `app/orders/repo.py` and implementation `app/infra/postgres/orders/repo.py` describe one semantic repo on opposite sides of a dependency boundary. A test fake is another implementation of that contract, not a second business repo.

When another independent service or repo is needed, reassess the feature boundary and introduce a meaningful submodule or separate feature with its own vocabulary. Do not merge unrelated responsibilities into a god service just to obey a filename limit. Conversely, do not split several coherent operations merely because there is more than one method.

## File or package

A file owns one coherent responsibility, not one symbol. Split when parts have independent reasons to change, different dependency directions or a useful separate testing boundary. Line count is a signal for inspection, not a mechanical threshold.

Use `<owner>/<role>/<name>.py` only when role and concrete name are genuinely independent axes. For one target, `entrypoint.py` is clearer than an `entrypoints/` package containing a single file. Avoid packages of identical wrappers whose only purpose is symmetry.

Imports should reveal ownership. Import the defining module rather than adding package facades, wildcard exports or `__init__.py` re-exports to hide paths. Keep package initialization free of registration and resource creation.

## Transport and infrastructure examples

For an existing API resource, `app/api/orders/router.py` owns routes and transport binding. `schemas.py` and `errors.py` are added there only for distinct transport responsibilities. Introduce a version segment such as `api/v1/` only when API versioning is an accepted contract; operational routes need not invent a product version.

Concrete SQL operations for orders belong in `app/infra/postgres/orders/repo.py`. ORM declarations can remain in `app/orders/models.py` under [the data boundary](contracts.md#data-and-orm-placement). Other vendor clients belong under their technology or integration owner, not in a generic client registry.

Test layout follows [testing](../conventions/testing.md), and dependency direction follows [system architecture](system.md). A directory move is not complete until imports, test ownership and knowledge links still express those boundaries.
