#! /bin/bash
#
# The latest version of this script can be found at
# https://gitlab.gnome.org/GNOME/citemplates

set -eu -o pipefail

if [[ "${PULL_CACHE:-0}" == "1" ]]; then
    # Make sure we don't end up with any leftover volume cache
    # as we are going to extract our own anyway
    rm --recursive --verbose --force .flatpak-builder
    echo "Pulling cache from ${ORAS_CACHE_IMAGE}"
    oras pull "${ORAS_CACHE_IMAGE}" || true
    tar --extract --xattrs --zstd --file "builder.tar.zstd" || true
    du  --human-readable --summarize "builder.tar.zstd" || true
fi
