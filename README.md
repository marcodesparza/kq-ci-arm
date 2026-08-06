# Container image to run OCA CI tests (arm64, Podman-first)

⚠️ These images are meant for running CI tests of Odoo addons in the OCA
style. They are *not* intended for any other purpose, and in particular they
are not fit for running Odoo in production. ⚠️

This is an **arm64 (aarch64)** fork of [OCA/oca-ci](https://github.com/OCA/oca-ci),
targeted at a single modern Odoo version (17/18/19), built and run primarily
with **Podman** (Docker also works).

Differences with upstream OCA/oca-ci:

- Base image is `debian:bookworm-slim` (arm64 native) instead of Ubuntu.
- `wkhtmltopdf` comes from the Debian package (official wkhtmltox `.deb`
  builds are x86_64-only). Caveat: Debian's build has no patched Qt, so HTML
  headers/footers in reports are not supported.
- `chromium` (Debian package) replaces Chrome for Testing, which has no
  official linux-arm64 build. A `google-chrome` symlink is provided for
  compatibility.
- No deadsnakes PPA (x86-only); the system Python 3.11 of bookworm is used.
- Legacy Python / Odoo ≤ 15 support was dropped.

These images provide the following guarantees:

- Odoo runtime dependencies are installed (`wkhtmltopdf`, `lessc`, etc).
- Odoo source code is in `/opt/odoo`.
- Odoo is installed in editable mode in a virtualenv isolated from system python packages.
- The Odoo configuration file exists at `$ODOO_RC`.
- The `python`, `pip` and `odoo` commands
  found first in `PATH` are from that virtualenv.
- `coverage` is installed in that virtualenv.
- Prerequisites for running Odoo tests are installed in that virtualenv
  (this notably includes `websocket-client` and the chromium browser for running
  browser tests).

Environment variables:

- `ODOO_VERSION` (17.0, 18.0, 19.0)
- `ODOO_RC`
- `PGHOST=postgres`
- `PGUSER=odoo`
- `PGPASSWORD=odoo`
- `PGDATABASE=odoo`
- `PIP_INDEX_URL=https://wheelhouse.odoo-community.org/oca-simple-and-pypi`
- `PIP_DISABLE_PIP_VERSION_CHECK=1`
- `PIP_NO_PYTHON_VERSION_WARNING=1`
- `ADDONS_DIR=.`
- `ADDONS_PATH=/opt/odoo/addons`
- `INCLUDE=`
- `EXCLUDE=`
- `OCA_GIT_USER_NAME=oca-ci`: git user name to commit `.pot` files
- `OCA_GIT_USER_EMAIL=oca-ci@odoo-community.org`: git user email to commit `.pot` files
- `OCA_ENABLE_CHECKLOG_ODOO=`: enable Odoo log error checking

Available commands:

- `oca_install_addons`: make addons to test (found in `$ADDONS_DIR`, modulo
  `$INCLUDE` an `$EXCLUDE`) and their dependencies available in the Odoo addons
  path. Append `addons_path=${ADDONS_PATH},${ADDONS_DIR}` to `$ODOO_RC`.
- `oca_init_test_database`: create a test database named `$PGDATABASE` with
  direct dependencies of addons to test installed in it
- `oca_run_tests`: run tests of addons on `$PGDATABASE`, with coverage.
- `oca_export_and_commit_pot`: export `.pot` files for all addons in
  `$ADDONS_DIR` that are installed in `$PGDATABASE`; git commit changes if any,
  using `$OCA_GIT_USER_NAME` and `$OCA_GIT_USER_EMAIL`.
- `oca_git_push_if_remote_did_not_change`: push local commits unless the remote
  tracked branch has evolved.
- `oca_export_and_push_pot` combines the two previous commands.
- `oca_checklog_odoo` checks odoo logs for errors (including warnings)

## Build

With the helper script (podman by default, docker via `OCI_RUNTIME=docker`):

```console
./build.sh                          # odoo 19.0, python 3.11
ODOO_VERSION=18.0 ./build.sh        # another modern Odoo
OCI_RUNTIME=docker ./build.sh       # force docker
```

Or directly:

```console
podman build --build-arg python_version=3.11 --build-arg odoo_version=19.0 -t oca-ci-arm .
```

Build args:

- python_version (default: 3.11)
- odoo_version (default: 19.0)
- odoo_org_repo (default: odoo/odoo)

## Tests

Tests are written using [pytest](https://pytest.org) in the `tests` directory.

You can run them using the `runtests.sh` script inside the container.

In the test directory, there is a `docker-compose.yml` to help run the tests.
It builds the image locally and starts a postgres service:

```console
# podman
podman compose -f tests/docker-compose.yml run --build test ./runtests.sh -v
# docker
docker compose -f tests/docker-compose.yml run --build test ./runtests.sh -v
```

This docker-compose mounts this project, and `runtests.sh` adds then `bin` directory to
the `PATH` for easier dev/test iteration.

## CI (GitHub Actions)

`.github/workflows/ci.yaml` builds the arm64 image and runs the test suite on
every push to `master` and every pull request, using the native arm64 GitHub
runner (`ubuntu-24.04-arm`, free for public repos). On pushes to `master`,
after the tests pass, the image is published to
`ghcr.io/<owner>/oca-ci-arm:py3.11-odoo19.0` (and `:latest`).

### Using the published image in other projects

Pull it directly instead of building:

```console
podman pull ghcr.io/<owner>/oca-ci-arm:py3.11-odoo19.0
```

and reference that image in your CI (e.g. `container:` in GitHub Actions, or
`image:` in a compose file), with a postgres service alongside.

Note: the first push creates the ghcr package as **private**. To make it
publicly pullable, go to the package page on GitHub → *Package settings* →
*Change visibility* → public (and link the package to this repository so it
shows up on the repo page).
