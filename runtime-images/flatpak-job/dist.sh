#! /bin/bash
#
# The latest version of this script can be found at
# https://gitlab.gnome.org/GNOME/citemplates

# rewrite-flatpak-manifest will make our checkout dirty and meson will complain
# FIXME: we need to copy the manifest rather than modify it in place to avoid making the checkout dirty
# Meson dist is still fine for now however, as meson will use the last commit rather than the current state of the repository
# FIXME: We end up creating 2 "build" sandboxes and its this one that ends up with the dist apparently
# our release service will be relying on the hardcoded path of
# build/${FLATPAK_MODULE}-2/_flatpak_build/meson-dist/${CI_PROJECT_NAME}-${CI_COMMIT_TAG}.tar.xz"
# to contain the tarball. This needs to never change.
# build/${FLATPAK_MODULE}/ is a symlink to -2 atm thankfully as well.

set -eu -o pipefail

if [[ "${MESON_DIST:-1}" == "1" ]]; then
    echo "Running meson dist!"
    flatpak-builder ${CI_FB_ARGS:-} \
        --default-branch="${default_branch}" \
        --ccache \
        --repo="${application_repo}" \
        --state-dir="${state_dir}" \
        --keep-build-dirs \
        --user \
        --disable-rofiles-fuse \
        --build-shell="${FLATPAK_MODULE}" \
        --disable-download \
        --disable-updates \
        "${application_directory}" \
         "${MANIFEST_PATH}" <<'END'
LANG=C.UTF-8 meson dist --no-tests --include-subprojects --allow-dirty
END

    dist_path="${state_dir}/build/${FLATPAK_MODULE}-2/_flatpak_build/meson-dist/"
    cp --recursive --preserve=all "$dist_path" "$project_dir/public-dist/"
fi

# Fix dist-path for artifacts
# Previously gitlab would create a copy of the files in the symlink `build/${FLATPAK_MODULE}-2/` ->  `build/${FLATPAK_MODULE}/`
# and the artifacts would contain the tarball under `build/${FLATPAK_MODULE}`. This changed recently
# and now symlinks are ignored, which broke the release-service component as we were recommending people use
# TARBALL_ARTIFACT_PATH: ".flatpak-builder/build/${FLATPAK_MODULE}/_flatpak_build/meson-dist/${CI_PROJECT_NAME}-${CI_COMMIT_TAG}.tar.xz"
# in the old handbook documentation.
# Manually unlink and move the meson-dist so things keep working.
dist_path="${state_dir}/build/${FLATPAK_MODULE}/_flatpak_build/meson-dist/"
dist_path_real="${state_dir}/build/${FLATPAK_MODULE}-2/_flatpak_build/meson-dist/"
if [[ -d "$dist_path" ]]; then
    unlink ${state_dir}/build/${FLATPAK_MODULE}
    mkdir -p ${state_dir}/build/${FLATPAK_MODULE}/_flatpak_build/
    mv "$dist_path_real" "${state_dir}/build/${FLATPAK_MODULE}/_flatpak_build/meson-dist/"
fi
