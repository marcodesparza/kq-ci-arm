#!/bin/bash
# Build the oca-ci arm64 image. Podman-first, falls back to docker.
#
# Usage:
#   ./build.sh                                  # defaults: odoo 19.0, python 3.11, odoo/odoo
#   ODOO_VERSION=18.0 ./build.sh                # pick another modern Odoo
#   OCI_RUNTIME=docker ./build.sh               # force docker
set -e

OCI_RUNTIME=${OCI_RUNTIME:-}
if [ -z "$OCI_RUNTIME" ]; then
    if command -v podman >/dev/null 2>&1; then
        OCI_RUNTIME=podman
    elif command -v docker >/dev/null 2>&1; then
        OCI_RUNTIME=docker
    else
        echo "error: neither podman nor docker found in PATH" >&2
        exit 1
    fi
fi

PYTHON_VERSION=${PYTHON_VERSION:-3.11}
ODOO_VERSION=${ODOO_VERSION:-19.0}
ODOO_ORG_REPO=${ODOO_ORG_REPO:-odoo/odoo}
IMAGE_NAME=${IMAGE_NAME:-localhost/oca-ci-arm:py${PYTHON_VERSION}-odoo${ODOO_VERSION}}

here=$(dirname "$0")

exec "$OCI_RUNTIME" build \
    --build-arg python_version="$PYTHON_VERSION" \
    --build-arg odoo_version="$ODOO_VERSION" \
    --build-arg odoo_org_repo="$ODOO_ORG_REPO" \
    -t "$IMAGE_NAME" \
    "$here"
