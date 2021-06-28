<p align="center">
  <img src="./logo/light.png" width="550"/>
</p>

<p align="center">
  <a title="'push' workflow Status" href="https://github.com/dbhi/containers/actions?query=workflow%3Apush"><img alt="'docker' workflow Status" src="https://img.shields.io/github/workflow/status/dbhi/containers/push/main?longCache=true&style=flat-square&logo=github&label=push"></a><!--
  -->
  <a title="Docker Hub" href="https://hub.docker.com/r/aptman/dbhi/"><img src="https://img.shields.io/docker/pulls/aptman/dbhi.svg?longCache=true&style=flat-square&logo=docker&logoColor=fff&label=aptman%2Fdbhi"></a><!--
  -->
</p>

This repository contains containerized open and free development tools for Dynamic Binary Hardware Injection (DBHI).
All the images are available at [docker.io/aptman/dbhi](https://hub.docker.com/r/aptman/dbhi/).
Images provided by [docker-library/official-images](https://github.com/docker-library/official-images#architectures-other-than-amd64)
are used as a base, and three host platforms are supported: `amd64`, `arm64v8` and `arm32v7`.
Manifests are also available, in order to allow platform-agnostic development.

- Any host:
  - `aptman/dbhi:bionic*`: [GHDL](https://github.com/ghdl/ghdl) (with LLVM backend and `--default-pic`), and
    [VUnit](https://github.com/VUnit/vunit) (Python 3).
    This is the *base* image.
  - `aptman/dbhi:bionic-dr*`: [DynamoRIO](https://github.com/DynamoRIO/dynamorio), based on *base* image.
  - `aptman/dbhi:bionic-cosim*`: *base* image plus [GTKWave](http://gtkwave.sourceforge.net/),
    [Flask](https://flask.palletsprojects.com/en/1.1.x/), [Pillow](https://pillow.readthedocs.io/en/stable/) and
    [numpy](https://numpy.org/).
  - `aptman/dbhi:bionic-octave*`: *base* image plus [Octave](https://www.gnu.org/software/octave/).

- `arm`|`arm64` only:
  - `aptman/dbhi:bionic-mambo-*`: [MAMBO](https://github.com/beehive-lab/mambo), based on *base* image.

- `amd64` only:
  - `aptman/dbhi:buster-gRPC-amd64`: [protoc](https://github.com/protocolbuffers/protobuf/),
    [grpc-go](https://github.com/grpc/grpc-go) and [protoc-gen-go](https://github.com/golang/protobuf/).
  - `aptman/dbhi:bionic-spinal*`: [SpinalHDL](https://github.com/SpinalHDL/SpinalHDL) and
    [RISCV dev tools](https://static.dev.sifive.com/dev-tools/).


> NOTE: binaries/artifacts built in `aptman/dbhi:bionic*` images can be executed on v2.3, v2.4 or v2.5 SDCard images
> provided at [Xilinx/PYNQ](https://github.com/Xilinx/PYNQ/releases), since those are based on `Ubuntu 18.04 (bionic)`.
> Releases are available for PYNQ, ZCU104 and ZCU111 boards.

## Usage

Some images include tools, such as GTKWave or Octave, that provide GUI interfaces.
These interfaces require an X server, which is expected to be executed outside of the container.
However, docker does not provide built-in options to automatically share the display from the host.
Furthermore, non-linux environments do not provide an X server by default.
Fortunately, [x11docker](https://github.com/mviereck/x11docker) and [runx](https://github.com/mviereck/runx) allow to
easily set up custom X servers on either GNU/Linux or Windows.

On GNU/Linux:

```sh
x11docker --hostdisplay -i aptman/dbhi:bionic-cosim bash
```

On Windows, with MSYS2 and VcxSrv:

```sh
x11docker --runx --no-auth -i aptman/dbhi:bionic-cosim bash
```

On Windows, with WSL or Cygwin, and Cygwin/X:

```sh
x11docker -i aptman/dbhi:bionic-cosim bash
```

Apart from these basic options, x11docker provides many [features](https://github.com/mviereck/x11docker#features)
focused on security; and remote access is supported.
See [JOSS 10.21105/joss.01349](https://joss.theoj.org/papers/10.21105/joss.01349).

## Continuous integration

Images for the three target platforms are built in a GitHub Actions workflow. [dbhi/qus](https://github.com/dbhi/qus) is
used to enable execution of images for foreign architectures (`arm64v8`|`arm32v7` on `amd64`).
See [push.yml](./.github/workflows/push.yml) and [run.sh](./run.sh) for further details.

## Building docker images for/on ARM targets

- SiFive does not provide prebuilt packages for ARM hosts: [sifive.com/boards](https://www.sifive.com/boards/).
  That's why `spinal` images for Arm platforms are not provided, although SpinalHDL can be successfully executed.

- Building image *dr* hangs the system on RPi3B. We should investigate why.
  However, DynamoRIO can be succesfully built natively.

- Building DynamoRIO on an arm32v7 container on a 64 bit host requires to set
  `-DCMAKE_SYSTEM_NAME=Linux -DCMAKE_SYSTEM_PROCESSOR=armv7`, as explained at DynamoRIO/dynamorio#3381.

> TODO Update either the Dockerfile or the build script according to
> [DynamoRIO/dynamorio#3381](https://github.com/DynamoRIO/dynamorio/issues/3381#issuecomment-468541604).
> Setting `CMAKE_SYSTEM_NAME` and `CMAKE_SYSTEM_PROCESSOR` seems not to be required if the ARM docker containers are
> executed on `x86_64` through `qemu-user-static` binaries (either `arm` or `AArch64`).

---

Compilation of either [GHDL](https://github.com/ghdl/ghdl/) or [DynamoRIO](https://github.com/DynamoRIO/dynamorio) fails
on `AArch64` with `kata-runtime` (see [katacontainers.io](https://katacontainers.io/)).
Multiple errors such as the following are shown:

- `Clock skew detected.  Your build may be incomplete.`
- `Warning: File <file> has modification time 0.008 s in the future`
- `cc1: out of memory allocating 65537 bytes after a total of 1466368 bytes`

This has been reported at [kata-containers/runtime#1293](https://github.com/kata-containers/runtime/issues/1293).

We tried to work around some of these issues with [`--cpuset-cpus`](https://docs.docker.com/v17.09/engine/admin/resource_constraints/#cpu),
so that make was executed on a single core.
However, DynamoRIO requires more than 3GB of RAM, and runtime option `-m` would fail with `kata-runtime` (see
[kata-containers/runtime#1245](https://github.com/kata-containers/runtime/issues/1245)).

The solution was to set `runc` as the default runtime. This was done through `/etc/systemd/system/docker.service.d/kata-containers.conf`
and/or `/etc/docker/daemon.json`.
See [Install Docker for Kata Containers on Ubuntu](https://github.com/kata-containers/documentation/blob/master/install/docker/ubuntu-docker-install.md#install-docker-for-kata-containers-on-ubuntu).
