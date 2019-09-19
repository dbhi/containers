# [DBHI] Dynamic Binary Hardware Injection: docker images

This repository contains containerized open and free development tools for decoupled functional hardware-software co-design on SoC, through injection of compiled HDL designs.

All the images currently available at [hub.docker.com/r/aptman/dbhi](https://hub.docker.com/r/aptman/dbhi/) are based on `Ubuntu 18.04 (bionic)`. Images provided by [docker-library/official-images](https://github.com/docker-library/official-images#architectures-other-than-amd64) are used and three host platforms are supported: `amd64`, `arm64v8` and `arm32v7`. Manifests are also available, in order to allow platform-agnostic development.


- Any host:
  - `aptman/dbhi:bionic*`: [GHDL](https://github.com/ghdl/ghdl) (with LLVM backend and `--default-pic`), and [VUnit](https://github.com/VUnit/vunit) (Python 3).
  - `aptman/dbhi:bionic-dr*`: [DynamoRIO](https://github.com/DynamoRIO/dynamorio).
  - `aptman/dbhi:bionic-gtkwave*`: [GTKWave](http://gtkwave.sourceforge.net/).
  - `aptman/dbhi:bionic-gui*`: *base* image plus GTKWave.
  - `aptman/dbhi:bionic-cosim*`: *gui* image plus [Flask](https://flask.palletsprojects.com/en/1.1.x/), [Pillow](https://pillow.readthedocs.io/en/stable/) and [numpy](https://numpy.org/).

- `arm`|`arm64` only:
  - `aptman/dbhi:bionic-mambo-*`: [MAMBO](https://github.com/beehive-lab/mambo).

- `amd64` only:
  - `aptman/dbhi:dev`: [Node.js](https://nodejs.org), [yarn](https://yarnpkg.com/) and [golang](https://golang.org/).
  - `aptman/dbhi:buster-gRPC-amd64`: [protoc](https://github.com/protocolbuffers/protobuf/), [grpc-go](https://github.com/grpc/grpc-go) and [protoc-gen-go](https://github.com/golang/protobuf/).
  - `aptman/dbhi:bionic-spinal*`: [SpinalHDL](https://github.com/SpinalHDL/SpinalHDL) and [RISCV dev tools](https://static.dev.sifive.com/dev-tools/).

## Continuous integration

Images for the three target platforms are built in a GitHub Actions workflow. [dbhi/qus](https://github.com/dbhi/qus) is used to enable execution of images for foreign architectures (`arm64v8`|`arm32v7` on `amd64`). See [push.yml](./.github/workflows/push.yml) and [run.sh](./run.sh) for further details.

## Building docker images for/on ARM targets

- SiFive does not provide prebuilt packages for ARM hosts: [sifive.com/boards](https://www.sifive.com/boards/). That's why `spinal` images for Arm platforms are not provided, although SpinalHDL can be successfully executed.

- Building image *dr* hangs the system on RPi3B. We should investigate why. However, DynamoRIO can be succesfully built natively.

- Building DynamoRIO on an arm32v7 container on a 64 bit host requires to set `-DCMAKE_SYSTEM_NAME=Linux -DCMAKE_SYSTEM_PROCESSOR=armv7`, as explained at DynamoRIO/dynamorio#3381.

> TODO Update either the Dockerfile or the build script according to [DynamoRIO/dynamorio#3381](https://github.com/DynamoRIO/dynamorio/issues/3381#issuecomment-468541604).
> Setting `CMAKE_SYSTEM_NAME` and `CMAKE_SYSTEM_PROCESSOR` seems not to be required if the ARM docker containers are executed on `x86_64` through `qemu-user-static` binaries (either `arm` or `AArch64`).

---

Compilation of either [GHDL](https://github.com/ghdl/ghdl/) or [DynamoRIO](https://github.com/DynamoRIO/dynamorio) fails on `AArch64` with `kata-runtime` (see [katacontainers.io](https://katacontainers.io/)). Multiple errors such as the following are shown:

- `Clock skew detected.  Your build may be incomplete.`
- `Warning: File <file> has modification time 0.008 s in the future`
- `cc1: out of memory allocating 65537 bytes after a total of 1466368 bytes`

This has been reported at [kata-containers/runtime#1293](https://github.com/kata-containers/runtime/issues/1293).

We tried to work around some of these issues with [`--cpuset-cpus`](https://docs.docker.com/v17.09/engine/admin/resource_constraints/#cpu), so that make was executed on a single core. However, DynamoRIO requires more than 3GB of RAM, and runtime option `-m` would fail with `kata-runtime` (see [kata-containers/runtime#1245](https://github.com/kata-containers/runtime/issues/1245)).

The solution was to set `runc` as the default runtime. This was done through `/etc/systemd/system/docker.service.d/kata-containers.conf` and/or `/etc/docker/daemon.json`. See [Install Docker for Kata Containers on Ubuntu](https://github.com/kata-containers/documentation/blob/master/install/docker/ubuntu-docker-install.md#install-docker-for-kata-containers-on-ubuntu).
