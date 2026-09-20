#! /bin/bash
#
# The latest version of this script can be found at
# https://gitlab.gnome.org/GNOME/citemplates

set -e -o pipefail
set +x

if [[ -n "${NIGHTLY_CACHE_ORAS_TOKEN_FILE:-}" ]] && [[ "${PUBLISH_CACHE:-0}" == "1" ]] && [[ "${CI_COMMIT_BRANCH}" == "${CI_DEFAULT_BRANCH}" ]]; then
    echo "Pruning ccache objects older than 90d..."
    ccache --show-stats --dir ${state_dir}/ccache/ --evict-older-than 90d

    echo "Uploading cache..."
    oras logout ${_ORAS_CACHE_REGISTRY} || true
    cat $NIGHTLY_CACHE_ORAS_TOKEN_FILE | oras login -u "${NIGHTLY_CACHE_ORAS_USER}" --password-stdin ${_ORAS_CACHE_REGISTRY} || true
    tar --create --xattrs --zstd --file "builder.tar.zstd" --exclude ${state_dir}/build --exclude ${state_dir}/rofiles ${state_dir}/ || true
    du -hs "builder.tar.zstd" || true
    oras push --annotation "quay.expires-after=30d" "$ORAS_CACHE_IMAGE" "builder.tar.zstd" || true
    oras logout ${_ORAS_CACHE_REGISTRY} || true
fi

