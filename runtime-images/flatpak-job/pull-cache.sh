#! /bin/bash
#
# The latest version of this script can be found at
# https://gitlab.gnome.org/GNOME/citemplates

set -eu -o pipefail

# Make sure we don't end up with any leftover volume cache
# as we are going to extract our own anyway
rm --recursive --verbose --force .flatpak-builder

app_id_lc=${APP_ID,,}
# FIXME: Only hardcode cache for main atm
# eventually we can also do stable branch caches but that needs more logic
# to determine when and what to pull and push
oras_branch=main
export registry="${_ORAS_CACHE_REGISTRY}/${_ORAS_CACHE_REPOSITORY}:${ARCH}-${app_id_lc}-${oras_branch}"
if [[ "$PULL_CACHE" == "1" ]]; then
    echo "Pulling cache from ${registry}"
    oras pull "$registry" || true
    tar --extract --xattrs --zstd --file "builder.tar.zstd" || true
    du  --human-readable --summarize "builder.tar.zstd" || true
fi
