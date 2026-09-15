#! /bin/bash
#
# The latest version of this script can be found at
# https://gitlab.gnome.org/GNOME/citemplates

# This file started its life as inline bash in the gitlab-ci scritp: yaml
# Lots of things can be improved now that we can have real bash (or even better python)
# However, we should invest in integrating the functionality (when possible) in our build
# tooling instead of making another, and horrible, build tool, that both special to CI and bash.

set -e -o pipefail

: "${MANIFEST_PATH:?MANIFEST_PATH is required}"
: "${FLATPAK_MODULE:?FLATPAK_MODULE is required}"
: "${APP_ID:?APP_ID is required}"

if [[ -n "${CI_PROJECT_DIR:-}" ]]; then
    git config --global --add safe.directory "${CI_PROJECT_DIR}"
fi

export project_dir="${CI_PROJECT_DIR:-$(pwd)}"
project_name="${CI_PROJECT_NAME:-${FLATPAK_MODULE}}"
commit_hash=$(git rev-parse --short=12 HEAD)

export ARCH="${ARCH:-$(arch)}"

# build-bundle
nightly_repo_url="https://nightly.gnome.org/gnome-nightly.flatpakrepo"
nightly_runtime_repo="https://nightly.gnome.org/repo/"
flatpak_repo_url="${REPO_URL:-${nightly_repo_url}}"
flatpak_runtime_repo="${RUNTIME_REPO:-${nightly_runtime_repo:-}}"

# Create a subject to add to the OSTree commit subject
# Mirrored from flathub
# https://github.com/flathub-infra/vorarbeiter/blob/0a3534f4aacc3962f46f85706872beb53eee261e/justfile#L18-L25
get_ostree_subject () {
    local subject
    local commit_msg

    commit_msg=$(git log -1 --pretty=%s)
    subject="$commit_msg ($commit_hash)"
    subject="${subject//[^[:ascii:]]/}"
    echo "${subject}"
}

get_default_branch () {
    local default_branch

    if [[ -n "${BRANCH:-}" ]]; then
        default_branch="$BRANCH"
    elif [[ -n "${CI_MERGE_REQUEST_IID:-}" ]]; then
        default_branch="mr-$CI_MERGE_REQUEST_IID"
    elif [[ -n "${CI_DEFAULT_BRANCH:-}" ]] && [[ "${CI_DEFAULT_BRANCH:-}" == "${CI_COMMIT_BRANCH:-}" ]]; then
        default_branch="master"
    else
        default_branch="test"
    fi
    echo "${default_branch}"
}

get_bundle_name () {
    local bundle
    if [[ -n "${BUNDLE:-}" ]]; then
        bundle="$BUNDLE"
    elif [[ -n "${CI_MERGE_REQUEST_IID:-}" ]]; then
        bundle="${project_name}-${ARCH}-mr-${CI_MERGE_REQUEST_IID}.flatpak"
    else
        bundle="${project_name}-${ARCH}-${commit_hash}.flatpak"
    fi
    echo "${bundle}"
}

rewrite_manifest () {
    local REWRITE_RUN_TESTS="--run-tests"
    if [[ "${RUN_TESTS:-1}" != "1" ]]; then
        REWRITE_RUN_TESTS="--no-run-tests"
    fi
    echo "RUN_TESTS: ${REWRITE_RUN_TESTS}"

    python3 /usr/lib/citemplates/rewrite-flatpak-manifest.py "${REWRITE_RUN_TESTS}" "${MANIFEST_PATH}" "${FLATPAK_MODULE}" -- ${CONFIG_OPTS:-}
}

print_bundle_url () {
    if [[ -n "${CI_JOB_URL:-}" ]]; then
        echo -e "Try this Flatpak build with:"
        echo -e "  $ wcurl $CI_JOB_URL/artifacts/raw/${bundle} --output /tmp/${bundle}"
        echo -e "  $ flatpak install --bundle /tmp/${bundle}"
        echo -e "(note that it might take a few minutes for artifacts to be available on the server)"
    # else
    #     # FIXME: this prints the container path
    #     $ flatpak install --bundle /build/gnome-font-viewer/gnome-font-viewer-x86_64-1c88eed2b01a.flatpak
    #     echo -e "Try this Flatpak build with:"
    #     echo -e "  $ flatpak install --bundle $project_dir/${bundle}"
    fi
}

determine_cache_image () {
    local nightly_cache_registry="quay.io"
    local nightly_cache_repository="gnome_infrastructure/gnome-nightly-cache"

    local app_id_lc=${APP_ID,,}
    # FIXME: Only hardcode cache for main atm
    # eventually we can also do stable branch caches but that needs more logic
    # to determine when and what to pull and push
    local oras_branch=main
    local registry="${_ORAS_CACHE_REGISTRY:-$nightly_cache_registry}"
    local namespace="${_ORAS_CACHE_REPOSITORY:-$nightly_cache_repository}"
    echo "$registry/$namespace:${ARCH}-${app_id_lc}-${oras_branch}"
}

# Make sure there is no leftover for whatever reason
rm -rf ./flatpak_app ./.flatpak-builder/build

# Make sure there is no leftover for whatever reason
rm -rf ./flatpak_app ./.flatpak-builder/build

bundle="$(get_bundle_name)"
readonly bundle
echo "Bundle filename: ${bundle}"

default_branch="$(get_default_branch)"
export default_branch
echo "Default Branch: ${default_branch}"

ORAS_CACHE_IMAGE="$(determine_cache_image)"
export ORAS_CACHE_IMAGE

bash /usr/lib/citemplates/print-info.sh

bash /usr/lib/citemplates/pull-cache.sh

rewrite_manifest

# Build. It will also run tests if we specified them in the manifest
echo "Running the build!"
xvfb-run -a -s "-screen 0 1024x768x24" -- dbus-run-session \
    flatpak-builder ${CI_FB_ARGS:-} \
    --default-branch="${default_branch}" \
    --ccache \
    --keep-build-dirs \
    --user \
    --disable-rofiles-fuse \
    --build-only flatpak_app \
    --repo=repo "${MANIFEST_PATH}"

# Run dist, if specified, and copy the tarball to export it
bash /usr/lib/citemplates/dist.sh

# Add metadata we get from gitlab to the bundle metadata
echo "Appending Gitlab Metadata to the ostree repo!"
python3 /usr/lib/citemplates/write_metadata.py flatpak_app/metadata

# Commit the build to the ostree repo
subject="$(get_ostree_subject)"
echo "Commit Subject: ${subject}"
echo "Finalizing the build"
flatpak-builder ${CI_FB_ARGS:-} \
    --default-branch="${default_branch}" \
    --ccache \
    --user \
    --disable-rofiles-fuse \
    --finish-only \
    --subject="${subject}" \
    --disable-download \
    --disable-updates flatpak_app \
    --repo=repo "${MANIFEST_PATH}"

# Generate a Flatpak bundle
echo "Generating Bundle!"
flatpak build-bundle \
    repo \
    "$project_dir/${bundle}" \
    ${EXPORT_RUNTIME:-} \
    --repo-url="${flatpak_repo_url}" \
    --runtime-repo="${flatpak_runtime_repo}" \
    "${APP_ID}" \
    "${default_branch}"

# Tar the repo for export in the artifacts, this gets consumed by the publish_nightly jobs
tar cf "$project_dir/repo.tar" repo/

# Export the documentation if it exist
docs_path="flatpak_app/files/share/doc/"
if [[ -d "$docs_path" ]]; then
    echo "Exporting documentation for artifacts"
    tar --create --auto-compress --file "${project_dir}/${project_name}-docs.tar.gz" --directory $docs_path .
fi

bash /usr/lib/citemplates/upload-cache.sh

# Print the link to the bundle
print_bundle_url
