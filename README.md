# CITemplates

This project provides reusable CI/CD components and legacy templates for jobs across multiple GNOME projects.

[[_TOC_]]

## Components

### gnomeos-build-sysext

The sysext component facilitates the creation of system extension images for GNOME OS.

```yaml
include:
  - component: gitlab.gnome.org/GNOME/citemplates/gnomeos-build-sysext@0.1.0
```

| Input                | Default value                | Description                                                         |
| -------------------- | ---------------------------- | ------------------------------------------------------------------- |
| `job-name`           |  `build-sysext`              | Name for the job                                                    |
| `job-stage`          |  `build`                     | Stage to run the job                                                |
| `extension-contents` |  `$CI_PROJECT_DIR/extension` | Path to a directory for the extension contents                      |
| `meson-options`      |  `""`                        | List of options to setup the meson project                          |

## Templates

### Flatpak

This is a legacy template for building Flatpak bundles. Visit the [wiki](https://gitlab.gnome.org/GNOME/Initiatives/-/wikis/DevOps-with-Flatpak) for more details.
