#! /bin/bash

set -eu

default_reg="quay.io/gnome_infrastructure/gnome-runtime-images"

if [ "${CI_COMMIT_REF_NAME:-}" == "master" ] && [ "${CI_PROJECT_NAMESPACE:-}" == "GNOME" ]; then
    img_reg="$default_reg"
    actual_tag="-base"
else
    img_reg="${CI_REGISTRY_IMAGE:-$default_reg}"
    actual_tag="-base-${CI_COMMIT_REF_SLUG:-local}"
fi

img_arch="${ARCH:-$(arch)}"
img_tag="${img_reg}:${img_arch}${actual_tag}"

echo "Building ${img_tag}"
buildah bud -t "${img_tag}" ./gnome-runtime-images

# push only on master branch
if [ "${CI_COMMIT_REF_NAME:-}" == "master" ]; then
    echo "Pushing ${img_tag}"
    buildah login -u "${OCI_REGISTRY_USER}" -p "${OCI_REGISTRY_PASSWORD}" quay.io
    buildah push "${img_tag}"
else
    echo "Pushing ${img_tag}"
    echo "$CI_JOB_TOKEN" | buildah login "$CI_REGISTRY" -u "$CI_REGISTRY_USER" --password-stdin
    buildah push "${img_tag}"
fi
