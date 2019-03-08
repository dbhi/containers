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

travis_start () {
  :
}
travis_finish () {
  :
}

if [ -n "$TRAVIS" ]; then
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
fi

#--

getDockerCredentialPass () {
:
#  PASS_URL="$(curl -s https://api.github.com/repos/docker/docker-credential-helpers/releases/latest | grep "browser_download_url.*pass-.*-amd64" | sed 's/.* "\(.*\)"/\1/g')"
#  [ "$(echo "$PASS_URL" | cut -c1-5)" != "https" ] && { PASS_URL="https://github.com/docker/docker-credential-helpers/releases/download/v0.6.0/docker-credential-pass-v0.6.0-amd64.tar.gz"; }
#  echo "PASS_URL: $PASS_URL"
#  curl -fsSL "$PASS_URL" | tar xv
#  chmod + $(pwd)/docker-credential-pass
}

#---

dockerLogin () {
#  if [ "$CI" = "true" ]; then
#    gpg --batch --gen-key <<-EOF
#%echo Generating a standard key
#Key-Type: DSA
#Key-Length: 1024
#Subkey-Type: ELG-E
#Subkey-Length: 1024
#Name-Real: DBHI
#Name-Email: umarcor/dbhi@github
#Expire-Date: 0
## Do a commit here, so that we can later print "done" :-)
#%commit
#%echo done
#EOF
#    key=$(gpg --no-auto-check-trustdb --list-secret-keys | grep ^sec | cut -d/ -f2 | cut -d" " -f1)
#    pass init $key
#  fi
  echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
}

#---

push () {
  imgs="ALL"
  if [ $# -ne 0 ] && [ "x$1" != "xALL" ]; then
    imgs="$@"
  fi

  getDockerCredentialPass
  dockerLogin

  for arch in $TARGET_ARCHS; do
    case $arch in
      aarch64|aarch32|armv7l|arm)
        if [ "x$imgs" = "xALL" ]; then
          imgs="main mambo dr gtkwave"
        fi
        case $arch in
          aarch64) arch="aarch64" ;;
          *)       arch="aarch32"
        esac
        for i in $imgs; do
          case $i in
            main|base)
              travis_start "base" "DOCKER push" "${DBHI_IMAGE}-$arch"
              docker push "${DBHI_IMAGE}-$arch"
              travis_finish "base"
            ;;
            mambo)
              travis_start "mambo" "DOCKER push" "${DBHI_IMAGE}-mambo-$arch"
              docker push "${DBHI_IMAGE}-mambo-$arch"
              travis_finish "mambo"
            ;;
            dr|dynamorio)
              travis_start "dr" "DOCKER push" "${DBHI_IMAGE}-dr-$arch"
              docker push "${DBHI_IMAGE}-dr-$arch"
              travis_finish "dr"
            ;;
            gtkwave)
              travis_start "gtkwave" "DOCKER push" "${DBHI_IMAGE}-gtkwave-$arch"
              docker push "${DBHI_IMAGE}-gtkwave-$arch"
              travis_finish "gtkwave"
            ;;
            grpc|gRPC|spinal)
              echo "Image <$i> not supported for arch <$arch> yet."
              exit 1
            ;;
            *)
              echo "Unknown image <$i> for host arch <$arch>"
              exit 1
          esac
        done
      ;;
      x86_64|amd64)
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
      ;;
      *)
        echo "Unknown arch $arch..."
        exit 1
    esac
  done

  docker logout
}

#---

manifests () {
  if [ -n "$TRAVIS" ]; then
    mkdir -p ~/.docker
    echo '{"experimental": "enabled"}' > ~/.docker/config.json
  fi

  getDockerCredentialPass
  dockerLogin

# https://github.com/docker/cli/issues/954

  docker manifest create -a "$DBHI_IMAGE" \
    "$DBHI_IMAGE"-amd64 \
    "$DBHI_IMAGE"-aarch64 \
    "$DBHI_IMAGE"-aarch32
  docker manifest push --purge "$DBHI_IMAGE"

  docker manifest create -a "$DBHI_IMAGE"-dr \
    "$DBHI_IMAGE"-dr-amd64 \
    "$DBHI_IMAGE"-dr-aarch64 \
    "$DBHI_IMAGE"-dr-aarch32
  docker manifest push --purge "$DBHI_IMAGE"-dr

  docker manifest create -a "aptman/dbhi:stretch-gRPC" \
    "aptman/dbhi:stretch-gRPC-amd64"
  docker manifest push --purge "aptman/dbhi:stretch-gRPC"

  docker manifest create -a "$DBHI_IMAGE"-gtkwave \
    "$DBHI_IMAGE"-gtkwave-amd64 \
    "$DBHI_IMAGE"-gtkwave-aarch64 \
    "$DBHI_IMAGE"-gtkwave-aarch32
  docker manifest push --purge "$DBHI_IMAGE"-gtkwave

  docker manifest create -a "$DBHI_IMAGE"-spinal \
    "$DBHI_IMAGE"-spinal-amd64
  docker manifest push --purge "$DBHI_IMAGE"-spinal

  docker logout
}

#---

build () {
  imgs="ALL"
  if [ $# -ne 0 ] && [ "x$1" != "xALL" ]; then
    imgs="$@"
  fi

  SLUG="aptman/dbhi:bionic"

  for arch in $TARGET_ARCHS; do
    case $arch in
      aarch64|aarch32|armv7l|arm)
        if [ "x$imgs" = "xALL" ]; then
          imgs="main mambo dr gtkwave"
        fi
        case $arch in
          aarch64)
            arch="aarch64"
            IMG="arm64v8/ubuntu:bionic"
          ;;
          *)
            arch="aarch32"
            IMG="arm32v7/ubuntu:bionic"
        esac
        for i in $imgs; do
          case $i in
            main|base)
              travis_start "base" "DOCKER build" "aptman/dbhi:bionic-$arch"
              docker build --build-arg IMAGE="$IMG" -t "${SLUG}-$arch" -f dockerfiles/main_ubuntu .
              travis_finish "base"
            ;;
            mambo)
              travis_start "mambo" "DOCKER build" "aptman/dbhi:bionic-mambo-$arch"
              docker build --build-arg IMAGE="${SLUG}-$arch" -t "${SLUG}-mambo-$arch" -f dockerfiles/mambo_ubuntu .
              travis_finish "mambo"
            ;;
            dr|dynamorio)
              travis_start "dr" "DOCKER build" "aptman/dbhi:bionic-dr-$arch"
              docker build --build-arg IMAGE="${SLUG}-$arch" -t "${SLUG}-dr-$arch" -f dockerfiles/dynamorio_ubuntu .
              travis_finish "dr"
            ;;
            gtkwave)
              travis_start "gtkwave" "DOCKER build" "aptman/dbhi:bionic-gtkwave-$arch"
              docker build --build-arg IMAGE="$IMG" -t "${SLUG}-gtkwave-$arch" -f dockerfiles/gtkwave_ubuntu .
              travis_finish "gtkwave"
            ;;
            grpc|gRPC|spinal)
              echo "Image <$i> not supported for arch <$arch> yet."
              exit 1
              #docker build --build-arg IMAGE="$IMG" -t "${SLUG}-spinal-$arch" -f dockerfiles/spinal_ubuntu .
            ;;
            *)
              echo "Unknown image <$i> for host arch <$arch>"
              exit 1
          esac
        done
      ;;
      x86_64|amd64)
        IMG="ubuntu:bionic"
        if [ "x$imgs" = "xALL" ]; then
          imgs="main dr gRPC gtkwave spinal"
        fi
        for i in $imgs; do
          case $i in
            main|base)
              travis_start "base" "DOCKER build" "aptman/dbhi:bionic-amd64"
              docker build --build-arg IMAGE="$IMG" -t "${SLUG}-amd64" -f dockerfiles/main_ubuntu .
              travis_finish "base"
            ;;
            dr|dynamorio)
              travis_start "dr" "DOCKER build" "aptman/dbhi:bionic-dr-amd64"
              docker build --build-arg IMAGE="${SLUG}-amd64" -t "${SLUG}-dr-amd64" -f dockerfiles/dynamorio_ubuntu .
              travis_finish "dr"
            ;;
            grpc|gRPC)
              travis_start "gRPC" "DOCKER build" "aptman/dbhi:stretch-gRPC-amd64"
              docker build -t aptman/dbhi:stretch-gRPC-amd64 -f dockerfiles/gRPC_stretch .
              travis_finish "gRPC"
            ;;
            gtkwave)
              travis_start "gtkwave" "DOCKER build" "aptman/dbhi:bionic-gtkwave-amd64"
              docker build --build-arg IMAGE="$IMG" -t "${SLUG}-gtkwave-amd64" -f dockerfiles/gtkwave_ubuntu .
              travis_finish "gtkwave"
            ;;
            spinal)
              travis_start "spinal" "DOCKER build" "aptman/dbhi:bionic-spinal-amd64"
              docker build --build-arg IMAGE="$IMG" -t "${SLUG}-spinal-amd64" -f dockerfiles/spinal_ubuntu .
              travis_finish "spinal"
            ;;
            mambo)
              echo "Image <$i> not supported for arch <$arch> yet."
            ;;
            *)
              echo "Unknown image <$i> for host arch <$arch>"
              exit 1
          esac
        done
      ;;
      *)
        echo "Unknown arch $arch..."
        exit 1
    esac
  done
}

#---

if [ -z "$TARGET_ARCHS" ]; then
  TARGET_ARCHS="$(uname -m)"
fi

DBHI_IMAGE="aptman/dbhi:bionic"

case "$1" in
  "-b")
    shift
    build "$@"
  ;;
  "-p")
    shift
    push "$@"
  ;;
  "-m")
    manifests
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
