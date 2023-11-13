# GNOME CI Templates

This repo contains Gitlab CI [YAML includes](https://docs.gitlab.com/ee/ci/yaml/includes.html)
with pre-defined CI jobs for use in GNOME apps and modules.

## Flatpak builds

The include [`flatpak/flatpak_ci_initiative.yml`](flatpak/flatpak_ci_initiative.yml)
provides CI jobs to build and publish your GNOME app as a Flatpak.

For more details see the ["DevOps with Flatpak" guide](https://gitlab.gnome.org/GNOME/Initiatives/-/wikis/DevOps-with-Flatpak).

## openQA tests using Flatpak

The include [`flatpak/openqa_flatpak.yml`](flatpak/openqa_flatpak.yml) provides
CI jobs to test your GNOME app with [openQA](http://open.qa/), using
GNOME OS as a base.

For more details see the ["Flatpak + openQA" guide](https://gitlab.gnome.org/GNOME/Initiatives/-/wikis/Flatpak-+-openQA).
