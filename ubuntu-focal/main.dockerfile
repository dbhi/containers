ARG IMAGE="ubuntu:focal"

ARG TAG_GHDL="7e41be2dabf79b21f3d0be210e3d01d541a7e82c"
ARG TAG_VUNIT="f344c8b5642d7aa13db2e16f6fc7151585ca96d0"

#
# Build GHDL
#

FROM $IMAGE AS build-base

ARG TAG_GHDL

RUN apt-get update -qq \
  && DEBIAN_FRONTEND=noninteractive apt-get -y install --no-install-recommends \
      ca-certificates \
      clang-9 \
      curl \
      gcc \
      git \
      gnat \
      llvm-9-dev \
      make \
      zlib1g-dev \
  && apt-get autoclean && apt-get clean && apt-get -y autoremove \
  && update-ca-certificates

RUN mkdir -p /tmp/ghdl && cd /tmp/ghdl \
 && curl -fsSL https://codeload.github.com/ghdl/ghdl/tar.gz/$TAG_GHDL | tar xzf - --strip-components=1 \
 && CXX=clang++-9 ./configure --with-llvm-config=llvm-config-9 --default-pic --disable-werror \
 && make \
 && make DESTDIR=/tmp/ghdl-llvm install

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
      libgnat-9 \
      libllvm9 \
      make \
      python3 \
      python3-pip \
      time \
      zlib1g-dev \
  && apt autoclean && apt clean && apt -y autoremove \
  && update-ca-certificates

COPY --from=build-base /tmp/ghdl-llvm /
COPY --from=get-vunit /opt/vunit/ /opt/vunit

RUN pip3 install -r /opt/vunit/requirements.txt

ENV PYTHONPATH=/opt/vunit
