#! /bin/bash

set -eu

default_reg="quay.io/gnome_infrastructure/gnome-runtime-images"
img_reg="${CI_REGISTRY_IMAGE:-$default_reg}"

REGISTRY_TAG="$1"

buildah manifest create "${REGISTRY_TAG}"

buildah manifest add "${REGISTRY_TAG}" "docker://${img_reg}:x86_64-${REGISTRY_TAG}"
buildah manifest add "${REGISTRY_TAG}" "docker://${img_reg}:aarch64-${REGISTRY_TAG}"

if [ "${CI_COMMIT_REF_NAME:-}" == "master" ]; then
    buildah login -u "${OCI_REGISTRY_USER}" -p "${OCI_REGISTRY_PASSWORD}" quay.io
    buildah manifest push --all "${REGISTRY_TAG}" "docker://${img_reg}:${REGISTRY_TAG}"
fi
