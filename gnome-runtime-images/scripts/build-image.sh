#! /bin/bash

set -eu

default_reg="quay.io/gnome_infrastructure/gnome-runtime-images"
actua_tag="-base"

img_reg="${CI_REGISTRY_IMAGE:-$default_reg}"
img_arch="${ARCH:-$(arch)}"
img_tag="${img_reg}:${img_arch}${actua_tag}"

echo "Building ${img_tag}"
buildah bud -t "${img_tag}" .

# push only on master branch
if [ "${CI_COMMIT_REF_NAME:-}" == "master" ]; then
    echo "Pushing ${img_tag}"
    buildah login -u "${OCI_REGISTRY_USER}" -p "${OCI_REGISTRY_PASSWORD}" quay.io
    buildah push "${img_tag}"
fi
