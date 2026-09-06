# Docker and Compose

## Applicability and ownership

Apply when a real process must be packaged for a container deployment or real integration dependencies need reproducible local/CI isolation. The seed does not need a Dockerfile simply to install an otherwise empty package.

This document owns image construction, container process boundaries, and Compose isolation. [Entrypoints](../architecture/entrypoints.md), [settings](../conventions/settings.md), [security](../conventions/security.md), and the chosen runtime recipes own application behavior.

Decide the runtime process, target CPU/platform, Python minor, writable paths, deployment user's permissions, startup dependencies, migration job, resource limits, health semantics, and signal/graceful shutdown contract. A container image is not a complete production deployment or a backup strategy.

## Image construction

Use an ordinary project Dockerfile, typically under `deploy/docker/`, once a deployable process exists. Add only deployment files required by that process. A single application image may serve API and worker roles through different explicit commands if they share the same dependency/runtime boundary; it does not need an internal role-selection framework.

Recommended construction properties:

- Pin the Python base image and uv version deliberately; use digests when the deployment's reproducibility policy requires immutable inputs.
- Use compatible builder/runtime base systems and the same Python minor. A copied virtual environment can contain native extensions and interpreter paths that are not portable across arbitrary images.
- Copy `pyproject.toml` and `uv.lock` before source to cache dependency installation.
- Validate lockfile freshness in the build or an enforced pre-build gate. `--frozen` uses a lock without checking whether it is current; it is not equivalent to `--locked` validation.
- Install only runtime dependencies into the application image. Install migration tooling in the image/job that actually executes migrations; do not assume an omitted dev group is available.
- Install the application non-editably or copy the source required by an intentional editable installation. Never copy a virtual environment whose editable path points to missing source.
- Run as a non-root user with only the writable directories it needs. Keep build compilers, test tools, and package-manager caches out of the final image when not required.
- Use exec-form `CMD`/`ENTRYPOINT` so the application receives termination signals. Do not wrap the process in a shell that silently becomes the signal owner.

Useful uv build-stage command shapes after choosing the exact image layout:

```sh
uv sync --locked --no-dev --no-install-project
uv sync --locked --no-dev --no-editable
```

The first command prepares locked dependencies without the local package; the second installs the package after its source/build inputs are copied. Verify behavior against the pinned uv and build backend, including whether README/license files are required by the package build. These commands are not a complete universal Dockerfile.

Maintain `.dockerignore` when adding a build context: exclude `.git`, `.venv`, local env/secrets, caches, build outputs, and unrelated artifacts while retaining required build inputs. Do not place tokens in build args or image layers; use supported secret mounts for private dependency access. Inspect image history and runtime environment for leaks.

## Runtime and health

Configure production bind address/port explicitly and inject settings at runtime through the deployment's secret/config boundary. Do not bake local credentials into images or Compose defaults. An `.env.example` documents safe shape and non-secret defaults, not usable production secrets.

Liveness and readiness have separate purposes as described by [FastAPI](fastapi.md). For a worker, use a meaningful process/broker readiness signal if an operator consumes it; do not run an otherwise unnecessary HTTP server just for a health endpoint. A Compose health dependency delays startup but does not implement reconnection or application recovery after a later outage.

Run migrations once in a deployment-owned step, not in every replica's entrypoint. Distinguish database initialization, schema compatibility, and application readiness. Decide restart policy and termination grace together with the actual workload, particularly [Taskiq](taskiq.md) execution/acknowledgement behavior.

A writable persistent volume is a deployment resource with ownership, retention, backup, and cleanup rules. Containers being replaceable does not make their data disposable.

## Local and CI Compose isolation

Create only the services required by current integration tests. Avoid a universal Compose file containing dormant Postgres/Redis/workers.

For concurrent developer and CI execution:

1. Use a unique Compose project name per test run.
2. Let the container runtime assign host ports where possible and discover the published bindings; avoid fixed-port collisions.
3. Wait for an explicit readiness condition with a bounded deadline. Do not use a fixed startup delay as a readiness oracle.
4. Feed the discovered endpoints to the consuming process through its actual settings contract.
5. Capture useful service logs on failure without printing secrets.
6. Clean only the project and volumes this run created. Register cleanup before partial startup can leave resources behind.
7. Preserve the original test failure exit status if cleanup also fails; if tests succeeded but cleanup failed, report the cleanup failure.

Do not reuse a developer's persistent database for destructive integration tests. `docker compose down --volumes` is appropriate only for an explicitly test-owned project whose volumes are disposable. It must not be a global cleanup command.

## Acceptance checks

1. Build from a clean checkout/context using the committed lockfile and the intended platform. A cached local editable environment does not establish image correctness.
2. Inspect the final user, installed runtime package, command, exposed ports, and required files. Verify that source/package imports work with no host bind mount.
3. Launch the actual process in the container, wait for readiness, and exercise one real vertical behavior through its external boundary.
4. Send the normal stop signal and verify graceful cleanup and bounded exit. For workers, check in-flight work according to the delivery contract.
5. Make a dependency unavailable after startup and verify the application's promised readiness/recovery behavior; Compose ordering alone does not prove it.
6. Run two isolated integration environments concurrently and verify independent ports, namespaces, and cleanup.
7. Test cleanup after partial startup and after a failing test; assert that the original failure remains visible.
8. Scan build context/config/logs for secrets and verify the final process can operate without root. A successful build does not establish vulnerability-free dependencies or production hardening.

## Sources and limits

Inspected [Vitok Dockerfile](https://github.com/kleksar/vitok/blob/6dc2ad3f75dd3860973cde08ea68f955af7fc4e2/deploy/docker/Dockerfile) and [isolated integration runner](https://github.com/kleksar/vitok/blob/6dc2ad3f75dd3860973cde08ea68f955af7fc4e2/scripts/ci_integration.sh). That Dockerfile used Python 3.14 and uv 0.10.5; those pins are historical source facts, not pins selected for future consuming images. Its product names, fixed process, env inventory, and source layout are not copied.

Upstream references: [Docker build documentation](https://docs.docker.com/build/) and [uv Docker integration](https://docs.astral.sh/uv/guides/integration/docker/). They were not fetched for this transfer. No Docker daemon is required to validate the seed itself, and these acceptance claims are not proven until a deployment capability exists.
