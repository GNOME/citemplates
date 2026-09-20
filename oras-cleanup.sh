#!/usr/bin/env bash
set -eu -o pipefail

declare -a images=(
    # fails
    "aarch64-org.freedesktop.sdk.extension.vala-nightly-main"
    # disabled
    "aarch64-org.gnome.calendar.devel-main"
    "aarch64-org.gnome.calls-main"
    "aarch64-org.gnome.decibels.devel-main"
    # broken
    "aarch64-org.gnome.resources.devel-main"
    # renamed
    "aarch64-org.gnome.tetravex-main"
    # fails
    "aarch64-org.gnome.tweaks-main"
    # Renamed
    "x86_64-app.gthumb.gthumb-main"
    # fails
    "x86_64-org.freedesktop.sdk.extension.vala-nightly-main"
    "x86_64-org.gnome.boxesdevel-main"
    "x86_64-org.gnome.calls-main"
    "x86_64-org.gnome.decibels.devel-main"
    # archived
    "x86_64-org.gnome.devhelp.devel-main"
    "x86_64-org.gnome.evince.devel-main"
    "x86_64-org.gnome.extensions.devel-main"
    "x86_64-org.gnome.five-or-more-main"
    # fails
    "x86_64-org.gnome.geary.devel-main"
    "x86_64-org.gnome.gitgdevel-main"
    "x86_64-org.gnome.libmks.mks-main"
    # renamed
    "x86_64-org.gnome.manette.test-main"
    # broken
    "x86_64-org.gnome.resources.devel-main"
    # renamed .devel
    "x86_64-org.gnome.reversi-main"
    # archived
    "x86_64-org.gnome.screenshot-main"
    # vala-nightly
    "x86_64-org.gnome.swellfoop-main"
    # renamed
    "x86_64-org.gnome.tetravex-main"
    # fails
    "x86_64-org.gnome.tweaks-main"
)

cat $NIGHTLY_CACHE_ORAS_TOKEN_FILE | oras login -u "${NIGHTLY_CACHE_ORAS_USER}" --password-stdin quay.io

for image in "${images[@]}"
do
    echo "$image"
    oras push --annotation "quay.expires-after=1h" "quay.io/gnome_infrastructure/gnome-nightly-cache:$image" "builder.tar.zstd"
done
