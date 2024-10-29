#!/usr/bin/env bash

# Based on install-nix-action by Cachix.
# See:
# https://github.com/cachix/install-nix-action/blob/master/install-nix.sh

# shellcheck shell=bash

NIX_VERSION='2.18.1'

set -euo pipefail

# Check if Nix is already installed
if nix_path="$(type -p nix || command -v nix)"; then
    echo "Aborting: Nix is already installed at ${nix_path}"
    exit
fi

echo "Installing Nix version ${NIX_VERSION}"

# Create a temporary workdir
workdir=$(mktemp -d)
trap 'rm -rf "$workdir"' EXIT

# Helper function for writing Nix configuration
function add_config() {
        [[ -n $1 ]] && echo "$1" >>"${workdir}/nix.conf"
}

# Add header comment
add_config "# Nix configuration reference:"
add_config "# https://nixos.org/manual/nix/stable/command-ref/conf-file.html"

# Basic config
add_config "experimental-features = nix-command flakes repl-flake"
add_config "system-features = nixos-test benchmark big-parallel kvm"
add_config "use-xdg-base-directories = true"
add_config "extra-nix-path = nixpkgs=flake:nixpkgs"

# Allow binary caches for user
add_config "trusted-users = root ${USER-}"

# Add default NixOS binary cache
add_config "substituters = https://cache.nixos.org/ https://prod-cache.vedenemo.dev"
add_config "trusted-substituters = https://cache.nixos.org/ https://prod-cache.vedenemo.dev"
add_config "trusted-public-keys = cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY= prod-cache.vedenemo.dev~1:JcytRNMJJdYJVQCYwLNsrfVhct5dhCK2D3fa6O1WHOI="
add_config "substitute = true"

# Optimize store disk usage
# add_config "auto-optimise-store = true"

# Set GC thresholds to instruct Nix to do GC if available disk-space
# in '/nix/store' drops below 'min-free' bytes during build.
# Nix keeps doing GC until there is no more garbage, or until 'max-free'
# bytes of disk space is available.
# add_config "min-free = $((25 * 1024 * 1024 * 1024))"
# add_config "max-free = $((50 * 1024 * 1024 * 1024))"

# Keep compilers, derivations and such when running GC.
# Also show stack trace on evaluation errors.
# add_config "keep-outputs = true"
# add_config "keep-derivations = true"
add_config "show-trace = true"

# Enable sandbox feature
add_config "sandbox = true"

# Maximum number of Nix jobs to build in parallel, 'auto' uses all available CPUs.
add_config "max-jobs = auto"

# This option controls the the parallelism of the builders, enabling
# parallel building at the discretion of the builders (by setting the
# NIX_BUILD_CORES env variable). For example for GNU Make this works
# just like passing the '-jN' flag to Make. Setting of '0' means
# use all available CPUs.
add_config "cores = 0"

unset -f add_config

# Nix installer flags
installer_options=(
    --nix-extra-conf-file "${workdir}/nix.conf"
    --daemon
    --yes
)

echo "Nix installer options:"
echo "${installer_options[*]}"

# There is --retry-on-errors, but only newer curl versions support that
curl_retries=5
while ! curl -sS -o "${workdir}/install" -v --fail -L "https://releases.nixos.org/nix/nix-${NIX_VERSION}/install"; do
    sleep 1
    ((curl_retries--))
    if [[ ${curl_retries} -le 0 ]]; then
        echo "curl retries failed" >&2
        exit 1
    fi
done

sh "${workdir}/install" "${installer_options[@]}"
