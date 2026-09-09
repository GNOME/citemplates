#! /bin/bash

set -eux

apt update -yq && apt install -y git
git clone --depth=1 https://gitlab.gnome.org/gnome/gnome-build-meta.git
