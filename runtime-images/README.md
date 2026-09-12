# Runtime Images

Pre built container images of the GNOME runtime to be used for building and
testing Flatpaks in the CI.

While we could install the Sdk on each job install, this gets slow and fast.
Additionally its not as reproducible.

The Gitlab CI runners operate on Docker/OCI images and they are really good at
caching those, as oppose to trying to cache a flatpak install invocation.

Every day (or on demand) we rebuild the CI image against the current GNOME
Nightly Runtime, this gets cached on the gitlab-runner on the first build of the
day, and stays there until a new image has been pushed. Thus, we only need to
install the runtime once in the image, and then distribute the image to every
Gitlab CI runner as needed.

## Testing local changes to the images

Images are built using `buildah` and its simple to rebuild them locally for
testing by using the same scripts that CI runs.

```bash
bash ./runtime-images/scripts/build-image.sh
# or podman tag localhost:x86_64-base-local localhost:base-local
bash ./runtime-images/scripts/make-manifest.sh base
bash ./runtime-images/scripts/build-sdk-image.sh "master" "26.08" "22" "22"
# or podman tag localhost:x86_64-gnome-master-local localhost:gnome-master-local
bash ./runtime-images/scripts/make-manifest.sh gnome-nightly
```

To test changes in the `flatpak-job` scripts, take a look at the
[test-local-image.sh](./test-local-image.sh) file

```bash
bash runtime-images/test-local-image.sh
```

The latest images can be downloaded from
[quay.io](https://quay.io/repository/gnome_infrastructure/gnome-runtime-images?tab=tags&tag=latest).
Older images can still be downloaded from
[gitlab.gnome.org](https://gitlab.gnome.org/GNOME/gnome-runtime-images/container_registry).
