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

[ ! "$JFROG_URL" ] && err_exit 1 "JFROG_URL undefined"
[ ! "$JFROG_UNAME" ] && err_exit 1 "JFROG_UNAME undefined"
[ ! "$JFROG_TOKEN" ] && err_exit 1 "JFROG_TOKEN undefined"

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

jf c add --url "$JFROG_URL" --user "$JFROG_UNAME" --access-token "$JFROG_TOKEN"
jf rt ping

for input in $INPUT_PATHS; do
  SOURCE_DIR=$(echo "$input" | cut -d ":" -f 1)
  DEST_DIR=$(echo "$input" | cut -d ":" -f 2)

  UPLOAD_DIR=$SOURCE_DIR
  echo "Run: jf rt u "$UPLOAD_DIR" "$DEST_DIR" --flat=true"
  jf rt u "$UPLOAD_DIR" "$DEST_DIR" --flat=true
done

echo "::endgroup::"
