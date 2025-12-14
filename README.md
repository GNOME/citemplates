# CITemplates

This project provides reusable CI/CD components and legacy templates for jobs
across multiple GNOME projects.

## Components

### gnomeos-basic-ci

This component will try to build and run the tests of your project against the
[GNOME OS](https://os.gnome.org/) image. It's ideal for projects that are not
actively maintained or do not have unique/complex requirements for running their
test suite.

It will also automatically extract any project documentation if build.
Additionally it will also create `dist` source archives of the project.

It can be combined with the `release-service` and `basic-deploy-docs` components
easily.

Example:

```yaml
include:
  - project: "gnome/citemplates"
    file: "templates/default-rules.yml"

  - component: "gitlab.gnome.org/GNOME/citemplates/gnomeos-basic-ci@25.6"
    inputs:
      before-script: "bash .gitlab-ci/my-before-script.sh"
      meson-options: >-
        -Ddocumentation=true
        -Dsysprof=true
        -Dinstall-tests=true
      lsan-options: "suppressions=${CI_PROJECT_DIR}/testsuite/lsan.supp"
      tsan: "disabled"

  - component: "gitlab.gnome.org/GNOME/citemplates/basic-deploy-docs@25.6"
    inputs:
      docs-job-name: "build-gnomeos"

  - component: "gitlab.gnome.org/GNOME/citemplates/release-service@25.6"
    inputs:
      dist-job-name: "build-gnomeos"
```

| Input                | Default value                | Description                                                         |
| -------------------- | ---------------------------- | ------------------------------------------------------------------- |
| `job-name`           |  `build-gnomeos`             | Name/Prefix for the jobs                                            |
| `job-stage`          |  `build`                     | Stage to run the job                                                |
| `image-ref`          |  `quay.io/gnome_infrastructure/gnome-build-meta:core-nightly`  | Specify the OCI image to use      |
| `meson-sourcedir`    |  `"."`(Current directory)    | "Meson sourcedir path. Useful if the project is not in the root directory"            |
| `meson-options`      |  `""` (Empty String)         | List of options to setup the meson project                                            |
| `meson-test-options` |  `""` (Empty String)         | List of additional options passed to meson test (ex "--exclude test-gobject-mkhtml")  |
| `run-tests`          |  `"yes"`                     | Whether to execute the testsuite pass empty value to skip                             |
| `before-script`      |  `null`                      | Optional before-script to execute                                                     |
| `clang`              |  `enabled`                   | Add a build job with clang                                                            |
| `asan`               |  `enabled`                   | Enable or Disable the asan build                                                      |
| `asan-options`       |  `enabled`                   | Value of ASAN_OPTIONS variable. Note it defaults to detect_leaks=0 since we have a separate lsan job |
| `lsan`               |  `enabled`                   | Enable or Disable the lsan build                                                      |
| `lsan-options`       |  `enabled`                   | Value of LSAN_OPTIONS variable.                                                       |
| `tsan`               |  `disabled`                  | Enable or Disable the tsan build                                                      |
| `tsan-options`       |  `enabled`                   | Value of TSAN_OPTIONS variable.                                                       |
| `ubsan`              |  `enabled`                   | Enable or Disable the ubsan build                                                     |
| `ubsan-options`      |  `enabled`                   | Value of UBSAN_OPTIONS variable.                                                      |
| `grcov-c`            |  `enabled`                   | Enable or Disable the grcov report. Tailored for C projects                           |
| `scan-build`         |  `enabled`                   | Enable or Disable the scan-build report                                               |

### gnomeos-build-sysext

The sysext component facilitates the creation of system extension images for
GNOME OS.

```yaml
include:
  - component: "gitlab.gnome.org/GNOME/citemplates/gnomeos-build-sysext@25.6"
```

| Input                | Default value                | Description                                                         |
| -------------------- | ---------------------------- | ------------------------------------------------------------------- |
| `job-name`           |  `build-sysext`              | Name for the job                                                    |
| `job-stage`          |  `build`                     | Stage to run the job                                                |
| `branch`             |  `nightly`                   | Branch of GNOME OS to use                                           |
| `before-script`      |  `null`                      | Optional before-script to execute                                   |
| `extension-contents` |  `$CI_PROJECT_DIR/extension` | Path to a directory for the extension contents                      |
| `meson-options`      |  `""`  (Empty String)        | List of options to setup the meson project                          |

### gnomeos-test-sysext

This component runs the specified openQA tests in GNOME OS with the system
extension enabled.

```yaml
include:
  - component: "gitlab.gnome.org/GNOME/citemplates/gnomeos-test-sysext@25.6"
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

In order for the extension to be enabled, the specified tests must include the
following in its `scenario_definitions.yaml` file:

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

Gitlab CI template for building Flatpak bundles. Visit the
[wiki](https://gitlab.gnome.org/GNOME/Initiatives/-/wikis/DevOps-with-Flatpak)
for more details. The template uses
[legacy YAML format](https://docs.gitlab.com/ee/development/cicd/templates.html).
