ARG IMAGE="ubuntu:focal"

ARG TAG_GHDL="b4d4d9abb322ed0807d2ba0888e73820499aa338"
ARG TAG_VUNIT="07a7c8be4cca23969ed8ef59d6387aa248364c4c"

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
 && CXX=clang++-6.0 ./configure --with-llvm-config=llvm-config-6.0 --default-pic --disable-werror \
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
      libgnat-7 \
      libllvm6.0 \
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
