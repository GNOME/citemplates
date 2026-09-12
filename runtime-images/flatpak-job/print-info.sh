#! /bin/bash
#
# The latest version of this script can be found at
# https://gitlab.gnome.org/GNOME/citemplates

set -eu -o pipefail
set -x

cat /etc/os-release

whoami && id -u && id -g

flatpak --version
flatpak-builder --version
bwrap --version

which bwrap
which flatpak
which flatpak-builder

# Report the installed versions of the runtime
flatpak info org.gnome.Platform
flatpak info org.gnome.Sdk

# Print the date, since appstream depends on local timezone
date && date -u

set +x
