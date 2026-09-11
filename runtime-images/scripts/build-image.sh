#! /bin/bash

set -eu -o pipefail

readonly architecture="${ARCH:-$(arch)}"
readonly tag="-base"

registry="${CI_REGISTRY_IMAGE:-localhost}"
tag_suffix="-${CI_COMMIT_REF_SLUG:-local}"
should_push=false

if [ "${CI_COMMIT_REF_NAME:-}" == "${CI_DEFAULT_BRANCH:-}" ] && [ "${CI_PROJECT_NAMESPACE:-}" == "GNOME" ]; then
    : "${OCI_REGISTRY_USER:?OCI_REGISTRY_USER is required}"
    : "${OCI_REGISTRY_PASSWORD:?OCI_REGISTRY_PASSWORD is required}"

    registry="quay.io/gnome_infrastructure/gnome-runtime-images"
    tag_suffix=""
    should_push=true

    echo "$CI_JOB_TOKEN" | buildah login quay.io -u "${OCI_REGISTRY_USER}" --password-stdin
elif [ -n "${CI_JOB_TOKEN:-}" ]; then
    : "${CI_REGISTRY:?CI_REGISTRY is required}"
    : "${CI_REGISTRY_USER:?CI_REGISTRY_USER is required}"

    should_push=true

    echo "$CI_JOB_TOKEN" | buildah login "$CI_REGISTRY" -u "$CI_REGISTRY_USER" --password-stdin
fi

readonly image_tag="${registry}:${architecture}${tag}${tag_suffix}"

echo "Building ${image_tag}"
buildah bud -t "${image_tag}" runtime-images

if [[ "$should_push" == true ]]; then
    echo "Pushing ${image_tag}"
    buildah push "${image_tag}"
else
    echo "No credentials configured. Skipping push of ${image_tag}"
fi
