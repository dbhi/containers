# Dynamic Binary Hardware Injection (DBHI)

This repository contains containerized open and free development tools for decoupled functional hardware-software co-design on SoCs with FPGA, through injection of compiled HDL designs using binary modification.

All the images currently available at [hub.docker.com/r/aptman/dbhi](https://hub.docker.com/r/aptman/dbhi/) are based on `Ubuntu 18.04 (bionic)`. Images provided by [docker-library/official-images](https://github.com/docker-library/official-images#architectures-other-than-amd64) are used for `amd64`, `arm64v8` and `arm32v7` platforms.

Manifest images are also provided, in order to allow platform-agnostic development:

> NOTE: The procedure below is used to update the manifests each time a corresponding image is updated. See [docker/cli#954](https://github.com/docker/cli/issues/954).

``` bash
DBHI_IMAGE="aptman/dbhi:bionic"
docker manifest push --purge "$DBHI_IMAGE"
docker manifest create -a "$DBHI_IMAGE" \
  "$DBHI_IMAGE"-amd64 \
  "$DBHI_IMAGE"-aarch64 \
  "$DBHI_IMAGE"-aarch32

docker manifest push --purge "$DBHI_IMAGE"-dr
docker manifest create -a "$DBHI_IMAGE"-dr \
  "$DBHI_IMAGE"-dr-amd64 \
  "$DBHI_IMAGE"-dr-aarch64 \
  "$DBHI_IMAGE"-dr-aarch32

docker manifest push --purge "$DBHI_IMAGE"-mambo
docker manifest create -a "$DBHI_IMAGE"-mambo \
  "$DBHI_IMAGE"-mambo-aarch64 \
  "$DBHI_IMAGE"-mambo-aarch32
```
