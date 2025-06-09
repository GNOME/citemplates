#! /bin/bash

set -eux

git clone --depth=1 https://gitlab.gnome.org/gnome/mutter.git
cd mutter
.gitlab-ci/install-gnomeos-sysext-dependencies.sh "${CI_PROJECT_DIR}"/extension
cd "${CI_PROJECT_DIR}"

set +x
