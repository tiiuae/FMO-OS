#!/bin/sh -l
# SPDX-FileCopyrightText: 2022-2024 TII (SSRC) and the Ghaf contributors
#
# SPDX-License-Identifier: Apache-2.0

BUILD_TARGET=$1
CACHIX_TOKEN=$2
RA_TOKEN=$3

SSH_DIR="/root/.ssh/"
RESULT_DIR="result/iso/"
RESULT_NAME="nixos.iso"
RESULT_COPY_DIR="./result_to_upload/"
SYS_USER_NAME="root"

err_print() {
  printf "%s" "$*" >&2
}

err_exit() {
  local rc=$1
  shift
  err_print "$@"
  exit "$rc"
}

echo "build target: $BUILD_TARGET"
cd $GITHUB_WORKSPACE

echo "::group::Input validation"
[ ! "$BUILD_TARGET" ] && err_exit 1 "BUILD_TARGET undefined"
[ ! "$CACHIX_TOKEN" ] && err_exit 1 "CACHIX_TOKEN undefined"
[ ! "$RA_TOKEN" ] && err_exit 1 "RA_TOKEN undefined"
echo "::endgroup::"

echo "::group::Install cachix"
nix-env -iA cachix -f https://cachix.org/api/v1/install
echo "Using cachix version:"
cachix --version || err_exit 1 "Cachix intallation has failed. Fail"
echo "::endgroup::"

echo "::group::Use FMO-OS cachix"
export USER=$SYS_USER_NAME
cachix authtoken $CACHIX_TOKEN
cachix use fmo-os || err_exit 1 "Cachix authentication has failed. Fail"
echo "::endgroup::"

echo "::group::Install RA deployment token"
# WAR: adding deployment token as user's ssh key
# Need a better way to do that
mkdir -p $SSH_DIR
echo "$RA_TOKEN" > $SSH_DIR/id_rsa
chmod 600 $SSH_DIR/id_rsa
echo "::endgroup::"

echo "::group::Add github to knownhosts"
mkdir -p $SSH_DIR
ssh-keyscan -t ed25519 -H github.com > $SSH_DIR/known_hosts
chmod 600 $SSH_DIR/known_hosts
echo "::endgroup::"

echo "::group::Build $BUILD_TARGET"
nix flake show
cachix watch-exec fmo-os -- \
  nix build -L --accept-flake-config .#$BUILD_TARGET
echo "::endgroup::"

echo "::group::Nix collect garbage"
nix-collect-garbage
echo "::endgroup::"

echo "::group::Copy results"
out=$(readlink -f $RESULT_DIR/$RESULT_NAME)
mkdir -p $RESULT_COPY_DIR
cp $out $RESULT_COPY_DIR/$RESULT_NAME || err_exit 1 "Result copy failed. Fail"
out=$(ls $RESULT_COPY_DIR/$RESULT_NAME)
echo "::endgroup::"


echo "::group::Validate out"
[ ! "$out" ] && err_exit 1 "There is no image has been built. Fail"

echo "outimg=$out" >> $GITHUB_OUTPUT
echo "::endgroup::"
