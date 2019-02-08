#!/bin/sh

set -e

cd "$(dirname $0)"

#---

enable_color() {
  ENABLECOLOR='-c '
  ANSI_RED="\033[31m"
  ANSI_GREEN="\033[32m"
  ANSI_YELLOW="\033[33m"
  ANSI_BLUE="\033[34m"
  ANSI_MAGENTA="\033[35m"
  ANSI_CYAN="\033[36;1m"
  ANSI_DARKCYAN="\033[36m"
  ANSI_NOCOLOR="\033[0m"
}

disable_color() { unset ENABLECOLOR ANSI_RED ANSI_GREEN ANSI_YELLOW ANSI_BLUE ANSI_MAGENTA ANSI_CYAN ANSI_DARKCYAN ANSI_NOCOLOR; }

enable_color

#---

travis_start () {}
travis_finish () {}

[ -n "$TRAVIS" ] && {
  # This is a trimmed down copy of
  # https://github.com/travis-ci/travis-build/blob/master/lib/travis/build/templates/header.sh
  travis_time_start() {
    # `date +%N` returns the date in nanoseconds. It is used as a replacement for $RANDOM, which is only available in bash.
    travis_timer_id=`date +%N`
    travis_start_time=$(travis_nanoseconds)
    echo "travis_time:start:$travis_timer_id"
  }
  travis_time_finish() {
    travis_end_time=$(travis_nanoseconds)
    local duration=$(($travis_end_time-$travis_start_time))
    echo "travis_time:end:$travis_timer_id:start=$travis_start_time,finish=$travis_end_time,duration=$duration"
  }

  if [ "$TRAVIS_OS_NAME" = "osx" ]; then
    travis_nanoseconds() {
      date -u '+%s000000000'
    }
  else
    travis_nanoseconds() {
      date -u '+%s%N'
    }
  fi

  travis_start () {
    echo "travis_fold:start:$1"
    travis_time_start
    printf "$ANSI_BLUE[$2] $3$ANSI_NOCOLOR\n"
  }

  travis_finish () {
    travis_time_finish
    echo "travis_fold:end:$1"
  }

}

#--

getDockerCredentialPass () {
  PASS_URL="$(curl -s https://api.github.com/repos/docker/docker-credential-helpers/releases/latest | grep "browser_download_url.*pass-.*-amd64" | sed 's/.* "\(.*\)"/\1/g')"
  [ "$(echo "$PASS_URL" | cut -c1-5)" != "https" ] && { PASS_URL="https://github.com/docker/docker-credential-helpers/releases/download/v0.6.0/docker-credential-pass-v0.6.0-amd64.tar.gz"; }
  echo "PASS_URL: $PASS_URL"
  curl -fsSL "$PASS_URL" | tar xv
  chmod + $(pwd)/docker-credential-pass
}

#---

dockerLogin () {
  if [ "$CI" = "true" ]; then
    gpg --batch --gen-key <<-EOF
%echo Generating a standard key
Key-Type: DSA
Key-Length: 1024
Subkey-Type: ELG-E
Subkey-Length: 1024
Name-Real: DBHI
Name-Email: umarcor/dbhi@github
Expire-Date: 0
# Do a commit here, so that we can later print "done" :-)
%commit
%echo done
EOF

    key=$(gpg --no-auto-check-trustdb --list-secret-keys | grep ^sec | cut -d/ -f2 | cut -d" " -f1)
    pass init $key

    echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
  fi
}

#---

push () {
  mkdir -p ~/.docker
  echo '{"experimental": "enabled"}' > ~/.docker/config.json
  getDockerCredentialPass
  dockerLogin

  DBHI_IMAGE="aptman/dbhi:bionic"

  travis_start "base" "DOCKER push" "${DBHI_IMAGE}-amd64"
  docker push "${DBHI_IMAGE}-amd64"
  travis_finish "base"

  travis_start "dr" "DOCKER push" "${DBHI_IMAGE}-dr-amd64"
  docker push "${DBHI_IMAGE}-dr-amd64"
  travis_finish "dr"

  travis_start "gRPC" "DOCKER push" "aptman/dbhi:stretch-gRPC-amd64"
  docker push "aptman/dbhi:stretch-gRPC-amd64"
  travis_finish "gRPC"

  travis_start "gtkwave" "DOCKER push" "${DBHI_IMAGE}-gtkwave-amd64"
  docker push "${DBHI_IMAGE}-gtkwave-amd64"
  travis_finish "gtkwave"

  travis_start "spinal" "DOCKER push" "${DBHI_IMAGE}-spinal-amd64"
  docker push "${DBHI_IMAGE}-spinal-amd64"
  travis_finish "spinal"

# https://github.com/docker/cli/issues/954

  docker manifest create -a "$DBHI_IMAGE" \
    "$DBHI_IMAGE"-amd64 \
    "$DBHI_IMAGE"-aarch64
  docker manifest push --purge "$DBHI_IMAGE"

  docker manifest create -a "$DBHI_IMAGE"-dr \
    "$DBHI_IMAGE"-dr-amd64 \
    "$DBHI_IMAGE"-dr-aarch64
  docker manifest push --purge "$DBHI_IMAGE"-dr

  docker manifest create -a "aptman/dbhi:stretch-gRPC" \
    "aptman/dbhi:stretch-gRPC-amd64"
  docker manifest push --purge "aptman/dbhi:stretch-gRPC"

  docker manifest create -a "$DBHI_IMAGE"-gtkwave \
    "$DBHI_IMAGE"-gtkwave-amd64
  docker manifest push --purge "$DBHI_IMAGE"-gtkwave

  docker manifest create -a "$DBHI_IMAGE"-spinal \
    "$DBHI_IMAGE"-spinal-amd64
  docker manifest push --purge "$DBHI_IMAGE"-spinal

  docker logout
}

#---

build () {
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
      travis_start "base" "DOCKER build" "aptman/dbhi:bionic-amd64"
      docker build -t aptman/dbhi:bionic-amd64 -f dbhi_ubuntu --build-arg IMAGE="ubuntu:bionic" --target base .
      travis_finish "base"

      travis_start "dr" "DOCKER build" "aptman/dbhi:bionic-dr-amd64"
      docker build -t aptman/dbhi:bionic-dr-amd64 -f dbhi_ubuntu --build-arg IMAGE="ubuntu:bionic" --target dr .
      travis_finish "dr"

      travis_start "gRPC" "DOCKER build" "aptman/dbhi:stretch-gRPC-amd64"
      docker build -t aptman/dbhi:stretch-gRPC-amd64 -f gRPC_stretch .
      travis_finish "gRPC"

      travis_start "gtkwave" "DOCKER build" "aptman/dbhi:bionic-gtkwave-amd64"
      docker build -t aptman/dbhi:bionic-gtkwave-amd64 -f gtkwave_ubuntu --build-arg IMAGE="ubuntu:bionic" .
      travis_finish "gtkwave"

      travis_start "spinal" "DOCKER build" "aptman/dbhi:bionic-spinal-amd64"
      docker build -t aptman/dbhi:bionic-spinal-amd64 -f spinal_ubuntu --build-arg IMAGE="ubuntu:bionic" .
      travis_finish "spinal"
      ;;
    *)
      echo "Unknown arch $arch..."
      ;;
  esac
}

#---

case "$1" in
  "-b")
    build $2
  ;;
  "-p")
    push
  ;;
  *)
    echo "Unknown arg <$1>"
  ;;
esac

#---

# Ubuntu 16.04
# ubuntu:xenial
# arm64v8/ubuntu:xenial

# Ubuntu 18.04
# ubuntu:bionic
# arm64v8/ubuntu:bionic
