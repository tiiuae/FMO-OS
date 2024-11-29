# Copyright 2022-2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{ pkgs, ... }:
let
  orchestrate-src = builtins.readFile ./assets/orchestrate.sh;
  orchestrate = (pkgs.writeScriptBin "orchestrate.sh" orchestrate-src).overrideAttrs(old: {
    buildCommand = "${old.buildCommand}\n patchShebangs $out";
  });

  trigger_orchestrate-src = builtins.readFile ./assets/trigger_orchestrate.sh;
  trigger_orchestrate = (pkgs.writeScriptBin "trigger_orchestrate.sh" trigger_orchestrate-src).overrideAttrs(old: {
    buildCommand = "${old.buildCommand}\n patchShebangs $out";
  });

  docker-login-src = builtins.readFile ./assets/docker-login.sh;
  docker-login = (pkgs.writeScriptBin "docker-login.sh" docker-login-src).overrideAttrs(old: {
    buildCommand = "${old.buildCommand}\n patchShebangs $out";
  });

  compose-image-src = builtins.readFile ./assets/compose-image.sh;
  compose-image = (pkgs.writeScriptBin "compose-image.sh" compose-image-src).overrideAttrs(old: {
    buildCommand = "${old.buildCommand}\n patchShebangs $out";
  });
in {
  environment.systemPackages = [ orchestrate trigger_orchestrate docker-login compose-image ];
}
