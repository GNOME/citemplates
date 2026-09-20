#!/usr/bin/env bash
set -eu -o pipefail

declare -a images=(
    # renamed
    "x86_64-org.gnome.nautiluspreviewerdevel-main"
    "aarch64-org.gnome.nautiluspreviewerdevel-main"
    # does not compile
    "x86_64-org.gnome.fileroller-main"
    "x86_64-org.gnome.usage.devel-main"
    "x86_64-org.gnome.restdemo-main"
    "x86_64-sm.puri.handy.glade-mai"
    "x86_64-org.gnome.soundjuicer-main"
    "x86_64-org.gnome.clocksdevel-main"
    "aarch64-org.gnome.clocksdevel-main"
    "x86_64-org.gnome.diskutility-main"
    "x86_64-sm.puri.handy.glade-main"
)

cat $NIGHTLY_CACHE_ORAS_TOKEN_FILE | oras login -u "${NIGHTLY_CACHE_ORAS_USER}" --password-stdin quay.io

for image in "${images[@]}"
do
    echo "$image"
    oras push --annotation "quay.expires-after=1h" "quay.io/gnome_infrastructure/gnome-nightly-cache:$image" "LICENSE"
done
