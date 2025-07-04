#! /bin/bash

set -eux

sed -i 's/^Types: deb$/Types: deb deb-src/' /etc/apt/sources.list.d/ubuntu.sources
apt update -yq && apt build-dep -y gnome-font-viewer
apt install -y git mutter meson gcc clang udev
git clone --depth=1 https://gitlab.gnome.org/gnome/gnome-font-viewer.git
