ARG IMAGE="ubuntu:bionic"

#
# Build GtkWave
#

FROM $IMAGE AS build-base

WORKDIR /work

RUN apt-get update -qq \
 && DEBIAN_FRONTEND=noninteractive apt-get -y install --no-install-recommends \
    ca-certificates \
    gcc \
    git \
    libstdc++-8-dev \
    make \
    build-essential \
    flex \
    gawk \
    gperf \
    libbz2-dev \
    libreadline-dev \
    libffi-dev \
    libgtk-3-dev \
    liblzma-dev \
    pkg-config \
    tcl-dev \
    tk-dev \
 && apt-get autoclean && apt-get clean && apt-get -y autoremove \
 && update-ca-certificates

RUN mkdir -pv /tmp/gtkwave && cd /tmp/gtkwave \
 && git clone https://github.com/gtkwave/gtkwave ./ \
 && cd gtkwave3-gtk3 \
 && ./configure --prefix="/usr/local" --with-tk=/usr/lib --enable-gtk3 \
 && make -j$(nproc) \
 && make check \
 && make install DESTDIR="/tmp/build-dir"

#
# GtkWave
#

FROM $IMAGE AS base

RUN apt update -qq \
 && DEBIAN_FRONTEND=noninteractive apt -y install --no-install-recommends \
    ca-certificates \
    gcc \
    git \
    graphviz \
    libc6-dev \
    libgnat-8 \
    libgtk-3-0 \
    libllvm6.0 \
    libtcl8.6 \
    libtk8.6 \
    make \
    python3 \
    python3-pip \
    tango-icon-theme \
    time \
    xdot \
    xterm \
    zlib1g-dev \
 && apt autoclean && apt clean && apt -y autoremove \
 && update-ca-certificates

#  && echo 'gtk-icon-theme-name = "Tango"' >> /usr/share/themes/Raleigh/gtk-2.0/gtkrc

COPY --from=build-base /tmp/build-dir/* /usr/local/

#
# amd64
#

FROM base AS amd64

RUN pip3 install flask Pillow numpy

#
# arm
#

FROM base AS arm

RUN apt update -qq \
 && DEBIAN_FRONTEND=noninteractive apt -y install --no-install-recommends \
   libjpeg-dev \
   libpython3-dev \
   libtiff5-dev \
   zlib1g-dev \
 && pip3 install setuptools wheel \
 && pip3 install Cython flask Pillow numpy
