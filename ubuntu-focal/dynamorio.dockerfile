ARG IMAGE="ubuntu:focal"

ARG TAG_DR="27193828261be587d06bcbbca3eabc49726d441f"

FROM $IMAGE

ARG TAG_DR

RUN apt update \
 && DEBIAN_FRONTEND=noninteractive apt install -y --no-install-recommends \
   cmake \
   gcc \
   g++ \
 && apt autoclean && apt clean && apt -y autoremove \
 && mkdir -p /tmp/dynamorio && cd /tmp/dynamorio \
 && curl -fsSL https://codeload.github.com/dynamorio/dynamorio/tar.gz/$TAG_DR | tar xzf - --strip-components=1 \
 && mkdir /opt/dynamorio && cd /opt/dynamorio \
 && cmake /tmp/dynamorio && make -j2 \
 && rm -rf /tmp/dynamorio

ENV DYNAMORIO_HOME /opt/dynamorio/
