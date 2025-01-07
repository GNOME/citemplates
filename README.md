# CITemplates

This project provides reusable CI/CD components and legacy templates for jobs across multiple GNOME projects.

[[_TOC_]]

## Components

### gnomeos-basic-ci

This component will try to build and run the tests of your project against the gnomeos image. It's ideal for projects that are not actively maintained or
have unique/complex requirements for running their test suite.

```yaml
include:
  - component: gitlab.gnome.org/GNOME/citemplates/gnomeos-basic-ci@master
  - project: "gnome/citemplates"
    file: "templates/default-rules.yml"
```

| Input                | Default value                | Description                                                         |
| -------------------- | ---------------------------- | ------------------------------------------------------------------- |
| `job-name`           |  `gnomeos-build`             | Name for the job                                                    |
| `job-stage`          |  `build`                     | Stage to run the job                                                |
| `branch`             |  `nightly`                   | Branch of GNOME OS to use                                           |
| `meson-options`      |  `""` (Empty String)         | List of options to setup the meson project                          |
| `run-tests`          |  `"yes"`                     | Whether to execute the testsuite pass empty value to skip           |


### gnomeos-build-sysext

The sysext component facilitates the creation of system extension images for GNOME OS.

```yaml
include:
  - component: gitlab.gnome.org/GNOME/citemplates/gnomeos-build-sysext@master
```

| Input                | Default value                | Description                                                         |
| -------------------- | ---------------------------- | ------------------------------------------------------------------- |
| `job-name`           |  `build-sysext`              | Name for the job                                                    |
| `job-stage`          |  `build`                     | Stage to run the job                                                |
| `branch`             |  `nightly`                   | Branch of GNOME OS to use                                           |
| `extension-contents` |  `$CI_PROJECT_DIR/extension` | Path to a directory for the extension contents                      |
| `meson-options`      |  `""`                        | List of options to setup the meson project                          |

### gnomeos-test-sysext

This component runs the specified openQA tests in GNOME OS with the system extension enabled.

```yaml
include:
  - component: gitlab.gnome.org/GNOME/citemplates/gnomeos-test-sysext@master
```

| Input          | Default value                | Description                              |
| -------------- | ---------------------------- | ---------------------------------------- |
| `job-name`     |  `test-sysext`               | Name for the job                         |
| `job-required` |  `build-sysext`              | Name of the job that built the extension |
| `job-stage`    |  `test`                      | Stage to run the job                     |
| `tests`        |  `tests/openqa`              | Path to the openQA tests directory       |

#### Variables

The following variables must set in the project [settings](https://docs.gitlab.com/ee/ci/variables/#define-a-cicd-variable-in-the-ui):

| Variable            | Description                                          |
| ------------------- | -----------------------------------------------------|
| `OPENQA_API_KEY`    | API key for [openQA](https://openqa.gnome.org/)      |
| `OPENQA_API_SECRET` | API secret for [openQA](https://openqa.gnome.org/)   |

#### Requirements

In order for the extension to be enabled, the specified tests must include the following in its `scenario_definitions.yaml` file:

```yaml
machines:
  qemu_x86_64:
    settings:
      HDD_2: /extension.sysext.raw
      NUMDISKS: '2'
      QEMU_SMBIOS: 'type=11,value=io.systemd.stub.kernel-cmdline-extra=systemd.mount-extra=/dev/vdb:/var/lib/extensions/extension'
```

## Templates

### Flatpak

Gitlab CI template for building Flatpak bundles. Visit the [wiki](https://gitlab.gnome.org/GNOME/Initiatives/-/wikis/DevOps-with-Flatpak) for more details. The template uses [legacy YAML format](https://docs.gitlab.com/ee/development/cicd/templates.html).
