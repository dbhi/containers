# [DBHI] Dynamic Binary Hardware Injection: docker images

This repository contains containerized open and free development tools for decoupled functional hardware-software co-design on SoCs with FPGA, through injection of compiled HDL designs using binary modification.

All the images currently available at [hub.docker.com/r/aptman/dbhi](https://hub.docker.com/r/aptman/dbhi/) are based on `Ubuntu 18.04 (bionic)`. Images provided by [docker-library/official-images](https://github.com/docker-library/official-images#architectures-other-than-amd64) are used for `amd64`, `arm64v8` and `arm32v7` platforms.

Manifest images are also provided, in order to allow platform-agnostic development.

## Building docker images for/on ARM targets

- Building `main`, `mambo`, `dr` and `spinal` images for AArch64 has been tested on Jetson, Merlin and Travis CI.
- Note that `spinal` images for ARM do not include a prebuilt GCC toolchain, because SiFive does not provide prebuilt packages for ARM hosts: [sifive.com/boards](https://www.sifive.com/boards/).

---

- `base` and `mambo` for AArch32 can be successfully built either on a Raspberry Pi 3 B (raspbian), Jetson or Merlin.
- Building `dr` hangs the system on the RPi3B. We should investigate why. However, DynamoRIO can be succesfully built natively.

- Building DynamoRIO on an arm32v7 container on an 64 bit host requires to set `-DCMAKE_SYSTEM_NAME=Linux -DCMAKE_SYSTEM_PROCESSOR=armv7`, as explained at DynamoRIO/dynamorio#3381.

> TODO Update either the Dockerfile or the build script according to [DynamoRIO/dynamorio#3381](https://github.com/DynamoRIO/dynamorio/issues/3381#issuecomment-468541604).
> Setting `CMAKE_SYSTEM_NAME` and `CMAKE_SYSTEM_PROCESSOR` seems not to be required if the ARM docker containers are executed on `x86_64` through `qemu-user-static` binaries (either `arm` or `AArch64`).

---

We found that compilation of either [GHDL](https://github.com/ghdl/ghdl/) or [DynamoRIO](https://github.com/DynamoRIO/dynamorio) fails on `AArch64` with `kata-runtime` (see [katacontainers.io](https://katacontainers.io/)), which is installed on Merlin. Multiple errors such as the following are shown:

- `Clock skew detected.  Your build may be incomplete.`
- `Warning: File <file> has modification time 0.008 s in the future`
- `cc1: out of memory allocating 65537 bytes after a total of 1466368 bytes`

This has been reported at [kata-containers/runtime#1293](https://github.com/kata-containers/runtime/issues/1293).

We tried to work around some of them with [`--cpuset-cpus`](https://docs.docker.com/v17.09/engine/admin/resource_constraints/#cpu), so that make was executed on a single core. However, DynamoRIO requires more than 3GB of RAM, and runtime option `-m` would fail with `kata-runtime` (see [kata-containers/runtime#1245](https://github.com/kata-containers/runtime/issues/1245)).

The solution was to set `runc` as the default runtime. This is done through `/etc/systemd/system/docker.service.d/kata-containers.conf` and/or `/etc/docker/daemon.json`. See https://github.com/kata-containers/documentation/blob/master/install/docker/ubuntu-docker-install.md#install-docker-for-kata-containers-on-ubuntu.
