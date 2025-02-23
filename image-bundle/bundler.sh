#!/bin/sh
set -x

OUTPUT=${OUTPUT:-"/hostdir/bundle.tar"}
K0S_BINARY=${K0S_BINARY:-"k0s"}
CTR_BIN=${CTR_BIN:-"ctr"}
CONTAINERD_RUN_SOCKET=${CONTAINERD_RUN_SOCKET:-"/run/containerd/containerd.sock"}
CTR_CMD="${CTR_BIN} --namespace bundle_builder --address ${CONTAINERD_RUN_SOCKET}"

function get_images() {
  cat /image.list | xargs
}

function ensure_images() {
  for image in $(get_images); do
    ${CTR_CMD} content fetch --platform ${TARGET_PLATFORM} $image
  done
}

function pack_images() {
  IMAGES=$(get_images)

  ${CTR_CMD} images export --platform ${TARGET_PLATFORM} $OUTPUT $IMAGES
}

function build_bundle() {
  ensure_images
  pack_images
}

if [ -z "${TARGET_PLATFORM}" ]; then
  echo "TARGET_PLATFORM must be set via env!!!"
  exit 1 
fi

containerd &

build_bundle

# Stop containerd
kill $(pidof containerd)