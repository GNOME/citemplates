#! /bin/bash
#
# The latest version of this script can be found at
# https://gitlab.gnome.org/GNOME/citemplates

# This file started its life as inline bash in the gitlab-ci scritp: yaml
# Lots of things can be improved now that we can have real bash (or even better python)
# However, we should invest in integrating the functionality (when possible) in our build
# tooling instead of making another, and horrible, build tool, that both special to CI and bash.

set -e -o pipefail

# Create a subject to add to the OSTree commit subject
# Mirrored from flathub
# https://github.com/flathub-infra/vorarbeiter/blob/0a3534f4aacc3962f46f85706872beb53eee261e/justfile#L18-L25
get_ostree_subject () {
    local subject
    local commit_msg
    local commit_hash

    commit_msg=$(git log -1 --pretty=%s)
    commit_hash=$(git rev-parse --short=12 HEAD)
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
    elif [[ -n "${CI_DEFAULT_BRANCH:-}" ]] && [[ "${CI_DEFAULT_BRANCH}" == "$CI_COMMIT_BRANCH" ]]; then
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
        bundle="${CI_PROJECT_NAME}-${ARCH}-mr-${CI_MERGE_REQUEST_IID}.flatpak"
    else
        bundle="${CI_PROJECT_NAME}-${ARCH}-${CI_COMMIT_SHORT_SHA}.flatpak"
    fi
    echo "${bundle}"
}

rewrite_manifest () {
    export REWRITE_RUN_TESTS="--run-tests"
    if [[ "${RUN_TESTS:-0}" != "1" ]]; then
        export REWRITE_RUN_TESTS="--no-run-tests"
    fi
    echo "RUN_TESTS: ${REWRITE_RUN_TESTS}"

    python3 /usr/lib/citemplates/rewrite-flatpak-manifest.py "${REWRITE_RUN_TESTS}" "${MANIFEST_PATH}" "${FLATPAK_MODULE}" -- ${CONFIG_OPTS:-}
}

print_bundle_url () {
    echo -e "Try this Flatpak build with:"
    echo -e "  $ wcurl $CI_JOB_URL/artifacts/raw/${bundle} --output /tmp/${bundle}"
    echo -e "  $ flatpak install --bundle /tmp/${bundle}"
    echo -e "(note that it might take a few minutes for artifacts to be available on the server)"
}

if [[ -n "${CI_PROJECT_DIR:-}" ]]; then
    git config --global --add safe.directory "${CI_PROJECT_DIR}"
fi

bundle="$(get_bundle_name)"
readonly bundle
echo "Bundle filename: ${bundle}"

default_branch="$(get_default_branch)"
export default_branch
echo "Default Branch: ${default_branch}"

export ARCH="${ARCH:-$(arch)}"

bash /usr/lib/citemplates/print-info.sh

# source for the $registry
source /usr/lib/citemplates/pull-cache.sh

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
    "$CI_PROJECT_DIR/${bundle}" \
    ${EXPORT_RUNTIME:-} \
    --repo-url="${REPO_URL:-$NIGHTLY_REPO_NONFILE}" \
    --runtime-repo="${RUNTIME_REPO:-$NIGHTLY_REPO}" \
    "${APP_ID}" \
    "${default_branch}"

# Tar the repo for export in the artifacts, this gets consumed by the publish_nightly jobs
tar cf "$CI_PROJECT_DIR/repo.tar" repo/

# Export the documentation if it exist
docs_path="flatpak_app/files/share/doc/"
if [[ -d "$docs_path" ]]; then
    # --file fallback should be pwd/flatpak-module-docs.tar.gz
    echo "Exporting documentation for artifacts"
    tar --create --auto-compress --file "${CI_PROJECT_DIR}/${CI_PROJECT_NAME}-docs.tar.gz" --directory $docs_path .
fi

bash /usr/lib/citemplates/upload-cache.sh

# Print the link to the bundle
print_bundle_url
