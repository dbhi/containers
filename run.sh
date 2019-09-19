#!/bin/sh

set -e

cd "$(dirname $0)"

export DOCKER_BUILDKIT=1

#---

enable_color() {
  ENABLECOLOR='-c '
  ANSI_RED="\033[31m"
  ANSI_GREEN="\033[32m"
  ANSI_YELLOW="\033[33m"
  ANSI_BLUE="\033[34m"
  ANSI_MAGENTA="\033[35m"
  ANSI_GRAY="\033[90m"
  ANSI_CYAN="\033[36;1m"
  ANSI_DARKCYAN="\033[36m"
  ANSI_NOCOLOR="\033[0m"
}

disable_color() { unset ENABLECOLOR ANSI_RED ANSI_GREEN ANSI_YELLOW ANSI_BLUE ANSI_MAGENTA ANSI_CYAN ANSI_DARKCYAN ANSI_NOCOLOR; }

enable_color

print_start() {
  if [ "x$2" != "x" ]; then
    COL="$2"
  elif [ "x$BASE_COL" != "x" ]; then
    COL="$BASE_COL"
  else
    COL="$ANSI_MAGENTA"
  fi
  printf "${COL}${1}$ANSI_NOCOLOR\n"
}

gstart () {
  print_start "$@"
}
gend () {
  :
}

if [ -n "$GITHUB_EVENT_PATH" ]; then
  export CI=true
fi

[ -n "$CI" ] && {
  gstart () {
    printf '::[group]'
    print_start "$@"
    SECONDS=0
  }

  gend () {
    duration=$SECONDS
    echo '::[endgroup]'
    printf "${ANSI_GRAY}took $(($duration / 60)) min $(($duration % 60)) sec.${ANSI_NOCOLOR}\n"
  }
} || echo "INFO: not in CI"

#---

get_all_list () {
  imgs="ALL"
  if [ $# -ne 0 ] && [ "x$1" != "xALL" ]; then
    echo "$@"
    return
  fi
  case $DBHI_ARCH in
    amd64)
      echo "main dr gRPC gtkwave gui cosim spinal dev"
    ;;
    arm64|arm)
      echo "main mambo dr gtkwave gui cosim"
    ;;
    *)
      echo "Unknown arch $DBHI_ARCH..."
      exit 1
  esac
}

#---

do_push () {
  gstart "[DOCKER push] $@"
  docker push "$@"
  gend
}

push () {
  imgs="$(get_all_list)"

  docker images

  echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin

  for i in $imgs; do
    case $i in
      dev)
        do_push "aptman/dbhi:dev"
      ;;
      main|base)
        do_push "${DBHI_SLUG}-$DBHI_ARCH"
      ;;
      mambo)
        if [ "x$DBHI_ARCH" = "xamd64" ]; then
          echo "Image <$i> not supported for arch <$DBHI_ARCH>."
          exit 1
        fi
        do_push "${DBHI_SLUG}-${i}-$DBHI_ARCH"
      ;;
      dr|dynamorio)
        do_push "${DBHI_SLUG}-dr-$DBHI_ARCH"
      ;;
      gtkwave|gui|cosim)
        do_push "${DBHI_SLUG}-${i}-$DBHI_ARCH"
      ;;
      grpc|gRPC)
        check_amd64only
        do_push "aptman/dbhi:buster-gRPC-amd64"
      ;;
      spinal)
        check_amd64only
        do_push "${DBHI_SLUG}-spinal-$DBHI_ARCH"
      ;;
      *)
        echo "Unknown image <$i> for host arch <$DBHI_ARCH>"
        exit 1
    esac
  done

  docker logout
}

#---

do_manifests () {
  slug="$1"
  shift
  args=""
  for s in $@; do
    args="$args ${slug}-$s"
  done
  gstart "[DOCKER manifest] $args"
  docker manifest create -a "$slug" $args
  gend
  gstart "[DOCKER push] $slug"
  docker manifest push --purge "$slug"
  gend
}

manifests () {
  if [ -n "$GITHUB_EVENT_PATH" ]; then
    mkdir -p ~/.docker
    echo '{"experimental": "enabled"}' > ~/.docker/config.json
  fi
  echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
  do_manifests "$DBHI_SLUG" amd64 arm arm64
  for m in dr gtkwave gui cosim; do
    do_manifests "${DBHI_SLUG}-$m" amd64 arm arm64
  done
  do_manifests "aptman/dbhi:buster-gRPC" amd64
  do_manifests "$DBHI_SLUG"-spinal amd64
  #docker logout
# https://github.com/docker/cli/issues/954
}

#---

do_build () {
  gstart "[DOCKER build] $1"
  docker build -t "$@"
  gend
}

do_build_imgarg () {
  gstart "[DOCKER build] $1"
  docker build -t "${DBHI_SLUG}-$1" --build-arg IMAGE="$2" - < "$3"
  gend
}

check_amd64only () {
  if [ "x$DBHI_ARCH" != "xamd64" ]; then
    echo "Image <$i> not supported for arch <$DBHI_ARCH> yet."
    exit 1
  fi
}

build () {
  imgs="ALL"
  if [ $# -ne 0 ] && [ "x$1" != "xALL" ]; then
    imgs="$@"
  fi

  case $DBHI_ARCH in
    amd64)
      IMG="ubuntu:bionic"
      if [ "x$imgs" = "xALL" ]; then
        imgs="main dr gRPC gtkwave gui cosim spinal dev"
      fi
    ;;
    arm64|arm)
      if [ "x$imgs" = "xALL" ]; then
        imgs="main mambo dr gtkwave gui cosim"
      fi
      case $DBHI_ARCH in
        arm64)
          arch="aarch64"
          IMG="arm64v8/ubuntu:bionic"
        ;;
        *)
          arch="aarch32"
          IMG="arm32v7/ubuntu:bionic"
      esac
    ;;
    *)
      echo "Unknown arch $DBHI_ARCH..."
      exit 1
  esac

  for i in $imgs; do
    case $i in
      dev)
        check_amd64only
        do_build aptman/dbhi:dev - < dev_ubuntu
      ;;
      main|base)
        do_build_imgarg "$DBHI_ARCH" "$IMG" main_ubuntu
      ;;
      mambo)
        if [ "x$DBHI_ARCH" = "xamd64" ]; then
          echo "Image <$i> not supported for arch <$DBHI_ARCH>."
          exit 1
        fi
        do_build_imgarg "${i}-$DBHI_ARCH" "${DBHI_SLUG}-$DBHI_ARCH" "${i}_ubuntu"
      ;;
      dr|dynamorio)
        do_build_imgarg "dr-$DBHI_ARCH" "${DBHI_SLUG}-$DBHI_ARCH" dynamorio_ubuntu
      ;;
      gtkwave)
        do_build_imgarg "${i}-$DBHI_ARCH" "$IMG" "${i}_ubuntu"
      ;;
      gui)
        do_build_imgarg "${i}-$DBHI_ARCH" "${DBHI_SLUG}-$DBHI_ARCH" gtkwave_ubuntu
      ;;
      cosim)
        do_build_imgarg "${i}-$DBHI_ARCH" "${DBHI_SLUG}-gui-$DBHI_ARCH" cosim_ubuntu_arm
      ;;
      grpc|gRPC)
        check_amd64only
        do_build aptman/dbhi:buster-gRPC-amd64 - < gRPC_buster
      ;;
      spinal)
        check_amd64only
        do_build_imgarg "spinal-amd64" "$IMG" spinal_ubuntu
      ;;
      *)
        echo "Unknown image <$i> for host arch <$DBHI_ARCH>"
        exit 1
    esac
  done
}

#---

DBHI_SLUG="aptman/dbhi:bionic"
echo "DBHI_SLUG: $DBHI_SLUG"

if [ -z "$TGT_ARCHS" ]; then
  TGT_ARCHS="$(uname -m)"
fi

for DBHI_ARCH in $TGT_ARCHS; do
  case $DBHI_ARCH in
    aarch64)
      DBHI_ARCH="arm64"
    ;;
    aarch32|armv7l|arm)
      DBHI_ARCH="arm"
    ;;
    x86_64|amd64)
      DBHI_ARCH="amd64"
    ;;
  esac
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
      exit 1
    ;;
  esac
done
