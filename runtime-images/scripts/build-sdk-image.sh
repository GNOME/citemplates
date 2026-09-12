#! /bin/bash

set -eu -o pipefail

BRANCH="$1"
FD_BRANCH="$2"
LLVM_VERSION="$3"
LLVM_VERSION_2="$4"

readonly architecture="${ARCH:-$(arch)}"
readonly base_manifest_tag="base"
readonly tag="-gnome-${BRANCH}"

registry="${CI_REGISTRY_IMAGE:-localhost}"
tag_suffix="-${CI_COMMIT_REF_SLUG:-local}"
should_push=false

if [ "${CI_COMMIT_REF_NAME:-}" == "${CI_DEFAULT_BRANCH:-}" ] && [ "${CI_PROJECT_NAMESPACE:-}" == "GNOME" ]; then
    : "${OCI_REGISTRY_USER:?OCI_REGISTRY_USER is required}"
    : "${OCI_REGISTRY_PASSWORD:?OCI_REGISTRY_PASSWORD is required}"

    registry="quay.io/gnome_infrastructure/gnome-runtime-images"
    tag_suffix=""
    should_push=true

    echo "$OCI_REGISTRY_PASSWORD" | buildah login quay.io -u "${OCI_REGISTRY_USER}" --password-stdin
elif [ -n "${CI_JOB_TOKEN:-}" ]; then
    : "${CI_REGISTRY:?CI_REGISTRY is required}"
    : "${CI_REGISTRY_USER:?CI_REGISTRY_USER is required}"

    should_push=true

    echo "$CI_JOB_TOKEN" | buildah login "$CI_REGISTRY" -u "$CI_REGISTRY_USER" --password-stdin
fi

readonly image_tag="${registry}:${architecture}${tag}${tag_suffix}"
echo "Building $image_tag"
CONTAINER=$(buildah from "${registry}:${base_manifest_tag}${tag_suffix}")

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
    "org.freedesktop.Sdk.Extension.rust-stable//${FD_BRANCH}" \
    "org.freedesktop.Sdk.Extension.vala//${FD_BRANCH}"

if [[ "$FD_BRANCH" == *26.08* ]]; then
    echo ""
    # buildah run "$CONTAINER" flatpak install flathub-beta --user --noninteractive \
    #     "org.freedesktop.Sdk.Extension.typescript//${FD_BRANCH}" \
    #     "org.freedesktop.Sdk.Extension.node26//${FD_BRANCH}"
else
    buildah run "$CONTAINER" flatpak install flathub --user --noninteractive \
        "org.freedesktop.Sdk.Extension.typescript//${FD_BRANCH}" \
        "org.freedesktop.Sdk.Extension.node24//${FD_BRANCH}"
fi

buildah run "$CONTAINER" flatpak install --user --noninteractive \
    "org.freedesktop.Sdk//${FD_BRANCH}"

# buildah run $CONTAINER flatpak install --user --noninteractive \
#     "org.freedesktop.Sdk.Extension.vala-nightly//${FD_BRANCH}"

buildah run "$CONTAINER" flatpak info --user "org.gnome.Platform//${BRANCH}"
buildah run "$CONTAINER" flatpak info --user "org.gnome.Sdk//${BRANCH}"

echo "Committing $image_tag"
buildah commit --squash "$CONTAINER" "$image_tag"

if [[ "$should_push" == true ]]; then
    echo "Pushing ${image_tag}"
    buildah push "${image_tag}"
else
    echo "No credentials configured. Skipping push of ${image_tag}"
fi
