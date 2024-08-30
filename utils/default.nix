# Copyright 2022-2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{lib, self, ghafOS}: {
  updateAttrs = (import ./updateAttrs.nix).updateAttrs;

  updateHostConfig = (import ./updateHostConfig.nix {inherit lib;});

  addSystemPackages = (packages: [({pkgs, ...}:{environment.systemPackages = map (app: pkgs.${app}) packages;})]);

  addCustomLaunchers =  (launchers: [{ghaf.graphics.app-launchers.enabled-launchers = launchers;}]);

  importvm = (vms: (map (vm: (import ../modules/virtualization/microvm/vm.nix {inherit ghafOS self; vmconf=vms.${vm};}) ) (builtins.attrNames vms)));
}
