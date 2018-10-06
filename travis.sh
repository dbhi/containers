#!/bin/sh

cd "$(dirname $0)"

arch="$(uname -m)"

if [ "$1" != "" ]; then
  arch="$1"
fi

case $arch in
  "aarch32")
    docker build -t aptman/dbhi:bionic-aarch32 -f dbhi_ubuntu --build-arg IMAGE="arm32v7/ubuntu:bionic" --target base .
    docker build -t aptman/dbhi:bionic-mambo-aarch32 -f dbhi_ubuntu --build-arg IMAGE="arm32v7/ubuntu:bionic" --target mambo .
    docker build -t aptman/dbhi:bionic-dr-aarch32 -f dbhi_ubuntu --build-arg IMAGE="arm32v7/ubuntu:bionic" --target dr .
    ;;
  "aarch64")
    docker build -t aptman/dbhi:bionic-aarch64 -f dbhi_ubuntu --build-arg IMAGE="arm64v8/ubuntu:bionic" --target base .
    docker build -t aptman/dbhi:bionic-mambo-aarch64 -f dbhi_ubuntu --build-arg IMAGE="arm64v8/ubuntu:bionic" --target mambo .
    docker build -t aptman/dbhi:bionic-dr-aarch64 -f dbhi_ubuntu --build-arg IMAGE="arm64v8/ubuntu:bionic" --target dr .
    #docker build -t aptman/dbhi:bionic-spinal-aarch64 -f dbhi_ubuntu --build-arg IMAGE="arm64v8/ubuntu:bionic" --target spinal .
    ;;
  "x86_64"*)
    docker build -t aptman/dbhi:bionic-amd64 -f dbhi_ubuntu --build-arg IMAGE="ubuntu:bionic" --target base .
    docker build -t aptman/dbhi:bionic-dr-amd64 -f dbhi_ubuntu --build-arg IMAGE="ubuntu:bionic" --target dr .
    docker build -t aptman/dbhi:bionic-spinal-amd64 -f dbhi_ubuntu --build-arg IMAGE="ubuntu:bionic" --target spinal .
    ;;
  *)
    echo "Unknown arch $arch..."
    ;;
esac

#---

# Ubuntu 16.04
# ubuntu:xenial
# arm64v8/ubuntu:xenial

# Ubuntu 18.04
# ubuntu:bionic
# arm64v8/ubuntu:bionic
