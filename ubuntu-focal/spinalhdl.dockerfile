ARG IMAGE="ubuntu:focal"

#
# SpinalHDL
#

FROM $IMAGE

# Set frontend required for docker
#ENV DEBIAN_FRONTEND noninteractive

RUN apt update \
 && apt install -y \
  apt-utils \
  apt-transport-https \
  ca-certificates \
  gnupg2 \
 && echo "deb https://repo.scala-sbt.org/scalasbt/debian all main" | tee /etc/apt/sources.list.d/sbt.list \
 && echo "deb https://repo.scala-sbt.org/scalasbt/debian /" | tee /etc/apt/sources.list.d/sbt_old.list \
 && curl -sL "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x2EE0EA64E40A89B84B2DF73499E82A75642AC823" | \
    sh -H gpg --no-default-keyring --keyring gnupg-ring:/etc/apt/trusted.gpg.d/scalasbt-release.gpg --import \
 && chmod 644 /etc/apt/trusted.gpg.d/scalasbt-release.gpg \
 && apt update \
 && apt install -y \
  g++ \
  openjdk-8-jdk \
  sbt \
  scala \
  wget

#--- SpinalHDL

RUN git clone https://github.com/SpinalHDL/SpinalHDL.git /opt/SpinalHDL \
 && cd /opt/SpinalHDL \
 && sbt clean compile publishLocal \
 && cd /opt \
 && git clone https://github.com/SpinalHDL/VexRiscvSocSoftware.git

#--- RICSV

ENV RISCV /opt/riscv
ENV NUMJOBS 1

ENV PATH $RISCV/bin:$PATH
RUN echo 'export PATH=/opt/riscv/bin:$PATH' >> $WORKDIR/.bashrc

ARG RISCV_GCC_VER=riscv64-unknown-elf-gcc-20170612-x86_64-linux-centos6

RUN cd /opt && wget https://static.dev.sifive.com/dev-tools/$RISCV_GCC_VER.tar.gz -q && \
    tar -xzvf $RISCV_GCC_VER.tar.gz && \
    mv $RISCV_GCC_VER /opt/riscv && \
    rm $RISCV_GCC_VER.tar.gz

RUN mkdir -p $RISCV/test && cd $RISCV/test \
 && echo '#include <stdio.h>\n int main(void) { printf("Hello world!\\n"); return 0; }' > hello.c \
 && riscv64-unknown-elf-gcc -o hello hello.c \
 && cd / && rm -rf $RISCV/test
