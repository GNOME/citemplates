#! /bin/bash

set -eux

dnf builddep -y gnome-font-viewer
dnf install -y git meson dbus-run-session mutter
git clone --depth=1 https://gitlab.gnome.org/gnome/gnome-font-viewer.git
