FROM quay.io/fedora/fedora:45

RUN dnf upgrade -y --best --allowerasing && \
    dnf install -y git 'dnf-command(builddep)' which meson && \
    dnf builddep -y flatpak

# Flatpak 1.15.6 has started using bwrap --disable-userns which is failing in the CI jobs
# as we can't write to /proc/sys/user/max_user_namespaces from the unprivilledged (and non-root)
# container that podman from gitlab-runner executes.
#
# Build our own pinned flatpak with said commit reverted, until we can come up with something better.
# https://github.com/flatpak/flatpak/commit/23ec4eda2f52e1570e2296061f9fd4763d7e3721
#
# Flathub has a patch that similar ot the revert one:
# https://github.com/flathub-infra/flatpak/commit/a750ddc815ed8cc1725ef7b8be16a1a734bd4fec
#
# Starting build of org.gnome.font-viewerDevel
# ========================================================================
# Building module gnome-font-viewer in /builds/alatiera/citemplates/.flatpak-builder/build/gnome-font-viewer-1
# ========================================================================
# bwrap: cannot open /proc/sys/user/max_user_namespaces: Permission denied
# Error: module gnome-font-viewer: Child process exited with code 1
RUN git clone --recursive --depth=1 -b alatiera/gnome-ci-bwrap https://github.com/alatiera/flatpak.git && \
    cd flatpak && \
    git checkout 947b8134c04001a9f05db7ff2d7db8e4375e4dee && \
    meson setup --prefix=/usr/local -Dtests=false -Ddocbook_docs=disabled -Dgtkdoc=disabled _build && \
    meson install -C _build --destdir=/flatpak/destdir

FROM quay.io/fedora/fedora:45
COPY --from=0 /flatpak/destdir/usr/local /usr/local/

RUN useradd --home-dir /build --create-home --shell /bin/bash build
WORKDIR /build

RUN dnf upgrade -y --best --allowerasing && \
    dnf install -y flatpak flatpak-builder librsvg2 ostree fuse elfutils ccache debugedit \
    dconf dbus-daemon dbus-tools git bzr xorg-x11-server-Xvfb dbus-x11 python3-ruamel-yaml \
    python3-gobject python3-pip json-glib jq tracker tracker-miners strace \
    mesa-vulkan-drivers mesa-libEGL mesa-libGL mutter xdg-desktop-portal xdg-desktop-portal-gnome && \
    dnf clean all

RUN which bwrap && which flatpak && which flatpak-builder
RUN flatpak --version && flatpak-builder --version && bwrap --version

# Private binaries/scripts go into /usr/lib
# We also don't need to mess with /usr/local since we control the image
COPY flatpak-job/* /usr/lib/citemplates/
COPY scripts/install-oras.sh /usr/lib/citemplates/
# /local/bin for backwards compatibility
# Drop this later
COPY flatpak-job/rewrite-flatpak-manifest.py /usr/local/bin/rewrite-flatpak-manifest

RUN bash /usr/lib/citemplates/install-oras.sh && rm /usr/lib/citemplates/install-oras.sh

# generate machine-id as specified in the freedesktop spec:
# https://www.freedesktop.org/software/systemd/man/machine-id.html
# for exmaple, gnome-builder test suite depends on this
RUN dbus-uuidgen > /etc/machine-id

USER build

RUN flatpak remote-add --user flathub https://dl.flathub.org/repo/flathub.flatpakrepo && \
    flatpak remote-add --user gnome-nightly https://nightly.gnome.org/gnome-nightly.flatpakrepo && \
    flatpak remote-add --user flathub-beta https://dl.flathub.org/beta-repo/flathub-beta.flatpakrepo
