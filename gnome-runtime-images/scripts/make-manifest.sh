#! /bin/bash

set -eu

default_reg="quay.io/gnome_infrastructure/gnome-runtime-images"

if [ "${CI_COMMIT_REF_NAME:-}" == "master" ] && [ "${CI_PROJECT_NAMESPACE:-}" == "GNOME" ]; then
    img_reg="$default_reg"
    REGISTRY_TAG="$1"
else
    img_reg="${CI_REGISTRY_IMAGE:-$default_reg}"
    REGISTRY_TAG="$1-${CI_COMMIT_REF_SLUG:-local}"
fi

echo "Creating ${REGISTRY_TAG}"
buildah manifest create "${REGISTRY_TAG}"

buildah manifest add "${REGISTRY_TAG}" "docker://${img_reg}:x86_64-${REGISTRY_TAG}"
buildah manifest add "${REGISTRY_TAG}" "docker://${img_reg}:aarch64-${REGISTRY_TAG}"

if [ "${CI_COMMIT_REF_NAME:-}" == "master" ]; then
    buildah login -u "${OCI_REGISTRY_USER}" -p "${OCI_REGISTRY_PASSWORD}" quay.io
    buildah manifest push --all "${REGISTRY_TAG}" "docker://${img_reg}:${REGISTRY_TAG}"
else
    echo "$CI_JOB_TOKEN" | buildah login "$CI_REGISTRY" -u "$CI_REGISTRY_USER" --password-stdin
    buildah manifest push --all "${REGISTRY_TAG}" "docker://${img_reg}:${REGISTRY_TAG}"
fi
