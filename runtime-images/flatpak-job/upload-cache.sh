#! /bin/bash
#
# The latest version of this script can be found at
# https://gitlab.gnome.org/GNOME/citemplates

set -e -o pipefail
set +x

# FIXME: this relies on the registry in the other script
if [[ -n "${NIGHTLY_CACHE_ORAS_TOKEN_FILE:-}" ]] && [[ "${PUBLISH_CACHE:-0}" == "1" ]] && [[ "${CI_COMMIT_BRANCH}" == "${CI_DEFAULT_BRANCH}" ]]; then
    echo "Uploading cache..."
    oras logout ${_ORAS_CACHE_REGISTRY} || true
    cat $NIGHTLY_CACHE_ORAS_TOKEN_FILE | oras login -u "${NIGHTLY_CACHE_ORAS_USER}" --password-stdin ${_ORAS_CACHE_REGISTRY} || true
    tar --create --xattrs --zstd --file "builder.tar.zstd" --exclude .flatpak-builder/build --exclude .flatpak-builder/rofiles .flatpak-builder/ || true
    du -hs "builder.tar.zstd" || true
    oras push $registry "builder.tar.zstd" || true
    oras logout ${_ORAS_CACHE_REGISTRY} || true
fi

