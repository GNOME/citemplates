#! /bin/bash

set -eu

BRANCH="$1"
FD_BRANCH="$2"
LLVM_VERSION="$3"
LLVM_VERSION_2="$4"

img_arch="${ARCH:-$(arch)}"
default_reg="quay.io/gnome_infrastructure/gnome-runtime-images"

if [ "${CI_COMMIT_REF_NAME:-}" == "master" ] && [ "${CI_PROJECT_NAMESPACE:-}" == "GNOME" ]; then
    img_reg="$default_reg"
    TAG="${img_reg}:${img_arch}-gnome-${BRANCH}"
    base_manifest_tag="base"
else
    img_reg="${CI_REGISTRY_IMAGE:-$default_reg}"
    TAG="${img_reg}:${img_arch}-gnome-${BRANCH}-${CI_COMMIT_REF_SLUG:-local}"
    base_manifest_tag="base-${CI_COMMIT_REF_SLUG:-local}"
fi

CONTAINER=$(buildah from "${img_reg}:${base_manifest_tag}")

echo "Building $TAG"

if [[ "$FD_BRANCH" == *beta ]]; then
    buildah run "$CONTAINER" flatpak install flathub-beta --user --noninteractive \
        "org.freedesktop.Platform.GL.default//${FD_BRANCH}"
else
    buildah run "$CONTAINER" flatpak install flathub --user --noninteractive \
        "org.freedesktop.Platform.GL.default//${FD_BRANCH}"
fi

if [ "$BRANCH" = "master" ]; then
    buildah run "$CONTAINER" flatpak install gnome-nightly --user --noninteractive \
        "org.gnome.Sdk//${BRANCH}" "org.gnome.Platform//${BRANCH}"
else
    buildah run "$CONTAINER" flatpak install --user --noninteractive \
        "org.gnome.Sdk//${BRANCH}" "org.gnome.Platform//${BRANCH}"
fi

buildah run "$CONTAINER" flatpak install --user --noninteractive \
    "org.freedesktop.Sdk.Extension.llvm${LLVM_VERSION_2}//${FD_BRANCH}" \
    "org.freedesktop.Sdk.Extension.llvm${LLVM_VERSION}//${FD_BRANCH}" \
    "org.freedesktop.Sdk.Extension.node24//${FD_BRANCH}" \
    "org.freedesktop.Sdk.Extension.rust-stable//${FD_BRANCH}" \
    "org.freedesktop.Sdk.Extension.typescript//${FD_BRANCH}" \
    "org.freedesktop.Sdk.Extension.vala//${FD_BRANCH}"

buildah run "$CONTAINER" flatpak install --user --noninteractive \
    "org.freedesktop.Sdk//${FD_BRANCH}"

buildah run $CONTAINER flatpak install --user --noninteractive \
    "org.freedesktop.Sdk.Extension.vala-nightly//${FD_BRANCH}"

buildah run "$CONTAINER" flatpak info --user "org.gnome.Platform//${BRANCH}"
buildah run "$CONTAINER" flatpak info --user "org.gnome.Sdk//${BRANCH}"

echo "Committing $TAG"
buildah commit --squash "$CONTAINER" "$TAG"

# push only on master branch
if [ "${CI_COMMIT_REF_NAME:-}" == "master" ]; then
    echo "Pushing ${TAG}"
    buildah login -u "${OCI_REGISTRY_USER}" -p "${OCI_REGISTRY_PASSWORD}" quay.io
    buildah push "${TAG}"
else
    echo "Pushing ${TAG}"
    echo "$CI_JOB_TOKEN" | buildah login "$CI_REGISTRY" -u "$CI_REGISTRY_USER" --password-stdin
    buildah push "${TAG}"
fi
