# Copyright 2022-2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{pkgs,lib, config, vmconf, ghafOS,microvmConfig,...}:
let
  inherit (import "${ghafOS.inputs.microvm}/lib" { nixpkgs-lib = lib; }) createVolumesScript makeMacvtap;
  inherit (makeMacvtap microvmConfig) openMacvtapFds macvtapFds;

  hypervisorConfig = import ("${ghafOS.inputs.microvm}/lib/runners/qemu.nix") {
    inherit pkgs microvmConfig macvtapFds;
  };

  inherit (hypervisorConfig) command canShutdown shutdownCommand;
  preStart = "DEVICE=$(cat /etc/microvm/${vmconf.name}/usb)";

  runScriptBin  = pkgs.writeScriptBin "microvm-run" ''
    #! ${pkgs.runtimeShell} -e

    ${preStart}
    ${createVolumesScript pkgs microvmConfig.volumes}
    ${lib.optionalString (hypervisorConfig.requiresMacvtapAsFds or false) openMacvtapFds}

    exec ${command} $DEVICE
  '';

in
  config.microvm.vms."${vmconf.name}".config.config.microvm.runner.qemu.overrideAttrs (oldAttrs: {
        buildCommand = oldAttrs.buildCommand or "" +
        ''
          ln -sf ${runScriptBin}/bin/microvm-run $out/bin/microvm-run
        '';
      })
