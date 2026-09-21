#! /bin/bash

set -eu -o pipefail

registry="${CI_REGISTRY_IMAGE:-localhost}"
REGISTRY_TAG="$1-${CI_COMMIT_REF_SLUG:-local}"
should_push=fasle

if [ "${CI_COMMIT_REF_NAME:-}" == "${CI_DEFAULT_BRANCH:-}" ] && [ "${CI_PROJECT_NAMESPACE:-}" == "GNOME" ]; then
    : "${OCI_REGISTRY_USER:?OCI_REGISTRY_USER is required}"
    : "${OCI_REGISTRY_PASSWORD:?OCI_REGISTRY_PASSWORD is required}"

    registry="quay.io/gnome_infrastructure/gnome-runtime-images"
    REGISTRY_TAG="$1"
    should_push=true

    echo "$OCI_REGISTRY_PASSWORD" | buildah login quay.io -u "${OCI_REGISTRY_USER}" --password-stdin
elif [ -n "${CI_JOB_TOKEN:-}" ]; then
    : "${CI_REGISTRY:?CI_REGISTRY is required}"
    : "${CI_REGISTRY_USER:?CI_REGISTRY_USER is required}"

    should_push=true

    echo "$CI_JOB_TOKEN" | buildah login "$CI_REGISTRY" -u "$CI_REGISTRY_USER" --password-stdin
fi

echo "Creating ${REGISTRY_TAG}"
buildah manifest create "${REGISTRY_TAG}"
buildah manifest add "${REGISTRY_TAG}" "docker://${registry}:x86_64-${REGISTRY_TAG}"
buildah manifest add "${REGISTRY_TAG}" "docker://${registry}:aarch64-${REGISTRY_TAG}"

if [[ "$should_push" == true ]]; then
    echo "Pushing ${registry}:${REGISTRY_TAG}"
    buildah manifest push --all "${REGISTRY_TAG}" "docker://${registry}:${REGISTRY_TAG}"
else
    echo "No credentials configured. Skipping push of ${REGISTRY_TAG}"
fi
