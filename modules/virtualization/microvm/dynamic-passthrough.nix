# Copyright 2022-2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{pkgs,lib, config, vmconf, ghafOS,microvmConfig,...}:
let
  inherit (import "${ghafOS.inputs.microvm}/lib" { nixpkgs-lib = lib; }) createVolumesScript makeMacvtap;
  inherit (makeMacvtap {
    inherit microvmConfig hypervisorConfig;
  }) openMacvtapFds macvtapFds;

  hypervisorConfig = import ("${ghafOS.inputs.microvm}/lib/runners/qemu.nix") {
    inherit pkgs microvmConfig macvtapFds;
  };
  inherit (hypervisorConfig) command canShutdown shutdownCommand;

  execArg = lib.optionalString microvmConfig.prettyProcnames
    ''-a "microvm@${microvmConfig.hostName}"'';


  inherit (import (./usb-passthrough-scripts.nix) {inherit pkgs;}) addUSB2kvm generateQemuUSBOptions;

  preStart = microvmConfig.preStart or "" + ''
    USB_LIST="${config.ghaf.virtualization.microvm."${vmconf.name}".passthroughDeviceListPath}"
    USB_PASSTHROUGH_OPTION=$(${generateQemuUSBOptions}/bin/generateQemuUSBOptions $USB_LIST)
    '';
  commandWithExtraArgument = command + "$USB_PASSTHROUGH_OPTION";

  runScriptBin  = pkgs.writeScriptBin "microvm-run" ''
    #! ${pkgs.runtimeShell} -e

    ${preStart}
    ${createVolumesScript pkgs microvmConfig.volumes}
    ${lib.optionalString (hypervisorConfig.requiresMacvtapAsFds or false) openMacvtapFds}

    exec ${commandWithExtraArgument}
  '';

in
  config.microvm.vms."${vmconf.name}".config.config.microvm.runner.qemu.overrideAttrs (oldAttrs: {
        buildCommand = oldAttrs.buildCommand or "" +
        ''
          ln -sf ${runScriptBin}/bin/microvm-run $out/bin/microvm-run
        '';
      })
