ARG IMAGE="ubuntu:bionic"

ARG TAG_GHDL="2e12aa8732cd49438a165a0b20c9acd9e37cde4d"
ARG TAG_VUNIT="7baf266bb7dd24ea5ee4e8ede4158526604dcf20"

#
# Build GHDL
#

FROM $IMAGE AS build-base

ARG TAG_GHDL

RUN apt-get update -qq \
  && DEBIAN_FRONTEND=noninteractive apt-get -y install --no-install-recommends \
      ca-certificates \
      clang-6.0 \
      curl \
      gcc \
      git \
      gnat \
      llvm-6.0-dev \
      make \
      zlib1g-dev \
  && apt-get autoclean && apt-get clean && apt-get -y autoremove \
  && update-ca-certificates

RUN mkdir -p /tmp/ghdl && cd /tmp/ghdl \
 && curl -fsSL https://codeload.github.com/ghdl/ghdl/tar.gz/$TAG_GHDL | tar xzf - --strip-components=1 \
 && CONFIG_OPTS="--default-pic " ./dist/travis/build.sh -b llvm-6.0 -p ghdl-llvm-fPIC \
 && mv ghdl-llvm-fPIC.tgz /tmp

#
# Get VUnit
#

FROM $IMAGE AS get-vunit

ARG TAG_VUNIT

RUN apt-get update -qq \
  && DEBIAN_FRONTEND=noninteractive apt-get -y install --no-install-recommends \
      ca-certificates \
      git \
 && git clone --recurse-submodule https://github.com/vunit/vunit /opt/vunit && cd /opt/vunit \
 && git checkout -b dbhi "$TAG_VUNIT" \
 && rm -rf .git

#
# Install GHDL and VUnit
#

FROM $IMAGE AS base

RUN apt update -qq \
  && DEBIAN_FRONTEND=noninteractive apt -y install --no-install-recommends \
      ca-certificates \
      curl \
      gcc \
      libgnat-7 \
      libllvm6.0 \
      make \
      python3 \
      python3-pip \
      time \
      zlib1g-dev \
  && apt autoclean && apt clean && apt -y autoremove \
  && update-ca-certificates

COPY --from=build-base /tmp/ghdl-llvm-fPIC.tgz /tmp/ghdl.tgz
COPY --from=get-vunit /opt/vunit/ /opt/vunit

RUN tar -xzf /tmp/ghdl.tgz -C /usr/local \
 && rm -f /tmp/* \
 && pip3 install -r /opt/vunit/requirements.txt

ENV PYTHONPATH=/opt/vunit
