# Copyright 2022-2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{
  description = "FMO-OS - Ghaf based configuration";

  nixConfig = {
    extra-trusted-substituters = [
      "https://prod-cache.vedenemo.dev"
      "https://cache.ssrcdevops.tii.ae"
    ];
    extra-trusted-public-keys = [
      "prod-cache.vedenemo.dev~1:JcytRNMJJdYJVQCYwLNsrfVhct5dhCK2D3fa6O1WHOI="
      "cache.ssrcdevops.tii.ae:oOrzj9iCppf+me5/3sN/BxEkp5SaFkHfKTPPZ97xXQk="
    ];
  };

  inputs = rec {
    ghafOS.url = "github:tiiuae/ghaf";
  };

  outputs = inputs @ {
    ghafOS,
    self,
    ...
  }: let
    # Retrieve inputs from Ghaf
    nixpkgs = ghafOS.inputs.nixpkgs;
    flake-parts = ghafOS.inputs.flake-parts;

    lib = nixpkgs.lib.extend (final: _prev: {
      ghaf = import "${ghafOS}/lib" {
        inherit self;
        lib = final;
      };
    });

    hwConfigs = [
      (import ./hardware/fmo-os-rugged-devices.nix)
      (import ./hardware/fmo-os-rugged-devices-public.nix)
    ];
    instConfigs = [
      (import ./installers/fmo-os-installer.nix)
      (import ./installers/fmo-os-installer-public.nix)
    ];
    updateAttrs = (import ./utils/updateAttrs.nix).updateAttrs;
    inheritConfig = confPath: { sysconf }: if lib.hasAttr "extend" sysconf
          then updateAttrs ["oss"] (import (lib.path.append confPath sysconf.extend) ).sysconf sysconf
          else sysconf;
    generateHwConfig = import ./config-processor-hardware.nix {inherit ghafOS self lib;};
    generateInstConfig = import ./config-processor-installers.nix {inherit ghafOS self lib;};
  
  in
    flake-parts.lib.mkFlake
    {
      inherit inputs;
    } {
      # Toggle this to allow debugging in the repl
      # see:https://flake.parts/debug
      debug = false;

      systems = [
        "x86_64-linux"
      ];

      imports = [
        ./hydrajobs/flake-module.nix
        ./modules/flake-module.nix
      ] ++ map generateHwConfig   (map (conf: inheritConfig ./hardware conf)   hwConfigs)
        ++ map generateInstConfig (map (conf: inheritConfig ./installers conf) instConfigs);

      flake.lib = lib;
    };
}
