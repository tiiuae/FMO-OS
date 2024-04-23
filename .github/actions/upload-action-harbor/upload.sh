#!/bin/bash -e
# SPDX-FileCopyrightText: 2022-2024 TII (SSRC) and the Ghaf contributors
#
# SPDX-License-Identifier: Apache-2.0

err_print() {
  printf "%s" "$*" >&2
}

err_exit() {
  local rc=$1
  shift
  err_print "$@"
  exit "$rc"
}

echo "::group::Input validation"

[ ! "$HARBOR_URL" ] && err_exit 1 "HARBOR_URL undefined"
[ ! "$HARBOR_UNAME" ] && err_exit 1 "HARBOR_UNAME undefined"
[ ! "$HARBOR_TOKEN" ] && err_exit 1 "HARBOR_TOKEN undefined"

for input in $INPUT_PATHS; do
  SOURCE_DIR=$(echo "$input" | cut -d ":" -f 1)
  DEST_DIR=$(echo "$input" | cut -d ":" -f 2)
  echo "SOURCE_DIR=$SOURCE_DIR"
  echo "DEST_DIR=$DEST_DIR"
  [ ! "$SOURCE_DIR" ] && err_exit 1 "SOURCE_DIR undefined"
  [ ! "$DEST_DIR" ] && err_exit 1 "DEST_DIR undefined"
done

echo "::endgroup::"
echo "::group::Artifact upload"

echo $HARBOR_TOKEN | oras login $HARBOR_URL -u $HARBOR_UNAME --password-stdin

for input in $INPUT_PATHS; do
  SOURCE_DIR=$(echo "$input" | cut -d ":" -f 1)
  DEST_DIR=$(echo "$input" | cut -d ":" -f 2)
  TAG=$(echo "$input" | cut -d ":" -f 3)

  UPLOAD_DIR=$SOURCE_DIR
  echo "oras push "$HARBOR_URL/$DEST_DIR:$TAG" $UPLOAD_DIR"
  oras push --disable-path-validation "$HARBOR_URL/$DEST_DIR:$TAG" $UPLOAD_DIR
done

echo "::endgroup::"
