#!/usr/bin/env bash

set -eux

citemplate_dir="$(pwd)"

upstream_image="quay.io/gnome_infrastructure/gnome-runtime-images:gnome-master"
# Non manifest one as its simpler
local_image="localhost:x86_64-gnome-master-local"

cache_dir="${XDG_CACHE_DIR:-$HOME/.cache}/citemplates"
seccomp_rules="$cache_dir/flatpak.seccomp.json"

global_setup () {
    mkdir -p "${cache_dir}"
    if [[ ! -f "${seccomp_rules}" ]]; then
        # https://github.com/gnome-infra/ansible/blob/master/roles/gitlab-runner/files/flatpak.seccomp.json
        wcurl --output "${seccomp_rules}" https://raw.githubusercontent.com/gnome-infra/ansible/refs/heads/master/roles/gitlab-runner/files/flatpak.seccomp.json
    fi
}

project_setup () {
    local url=$1
    local project_dir=$2

    project_path="${cache_dir}/${project_dir}"

    if [[ ! -d $project_path ]]; then
        git clone --depth=1 "$url" "${project_path}"

    fi

    # https://github.com/flatpak/flatpak-builder/issues/615
    git -C "${project_path}" config core.fsmonitor false
    git -C "${project_path}" fsmonitor--daemon stop || true
    git -C "${project_path}" fsmonitor--daemon status || true
}

# podman setup:
# https://github.com/gnome-infra/ansible/blob/6fc0dd1eccc4ac131c4b62017f287030532d8e9c/inventory/host_vars/redhat-runner-04#L34-L47
#
# privileged: false
# cap_drop:
#   - all
# security_opt:
#   - seccomp:/home/podman/gitlab-runner/flatpak.seccomp.json
#   - "label=level:s0:c100,c100"
# disable_entrypoint_overwrite: false
# oom_kill_disable: false
# disable_cache: true
# shm_size: 0
# volumes:
#   - /proc:/host/proc
# tmpfs:
#   "/tmp": "rw,nosuid,nodev,exec,mode=1777"
podman_run () {
    local project=$1
    local manifest_path=$2

    # It can be hundreds of megabytes and its usually
    # faster and more thorough testing to make sure
    # everything builds
    local pull_cache=0

    podman run --rm -ti \
        --volume="${cache_dir}/${project}:/build/${project}" \
        --volume="${citemplate_dir}/runtime-images/flatpak-job:/usr/lib/citemplates/" \
        --workdir="/build/${project}" \
        --privileged=false \
        --cap-drop=all \
        --security-opt="seccomp:${seccomp_rules}" \
        --security-opt="label=level:s0:c100,c100" \
        --volume /proc:/host/proc \
        --tmpfs "/tmp=rw,nosuid,nodev,exec,mode=1777" \
        --shm-size=0 \
        --userns=keep-id \
        --env="PULL_CACHE=$pull_cache" \
        --env="MANIFEST_PATH=${manifest_path}" \
        --env="FLATPAK_MODULE=${project}" \
        $local_image \
        bash /usr/lib/citemplates/flatpak-job.sh
}

test_font_viewer () {
    local url="https://gitlab.gnome.org/gnome/gnome-font-viewer.git"
    local manifest_path="build-aux/flatpak/org.gnome.font-viewerDevel.json"
    local project="gnome-font-viewer"

    project_setup $url $project
    podman_run $project $manifest_path
}

test_nautilus () {
    local url="https://gitlab.gnome.org/gnome/nautilus.git"
    local manifest_path="build-aux/flatpak/org.gnome.Nautilus.json"
    local project="nautilus"

    project_setup $url $project
    podman_run $project $manifest_path
}

test_epiphany () {
    local url="https://gitlab.gnome.org/gnome/epiphany.git"
    local manifest_path="org.gnome.Epiphany.json"
    local project="epiphany"

    project_setup $url $project
    podman_run $project $manifest_path
}

global_setup
# test_font_viewer
# test_nautilus
test_epiphany
