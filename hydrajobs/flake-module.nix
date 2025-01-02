# Copyright 2022-2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
#
# TODO: For more robust target collection, maybe add an attribute
# to the package config, or some similar trickery instead of
# just checking the package name.
#
# Reference: https://wiki.nixos.org/wiki/Flakes#Output_schema
# hydraJobs."<attr>"."<system>" = derivation;
{
  self,
  lib,
  ...
}: let
  packageFilter = name: value: ((lib.hasInfix "public" name) && !(lib.hasInfix "compressed" name));
in {
  flake.hydraJobs =
    lib.foldlAttrs
    (
      acc: system: packages: let
        publicPackages = lib.filterAttrs packageFilter packages;
      in
        acc // (lib.mapAttrs' (name: package: lib.nameValuePair name {${system} = package;}) publicPackages)
    )
    {}
    self.packages;
}
