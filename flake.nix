# Copyright 2022-2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{
  description = "FMO-OS - Ghaf based configuration";

  nixConfig = {
    extra-trusted-substituters = [
      "https://cache.vedenemo.dev"
      "https://cache.ssrcdevops.tii.ae"
    ];
    extra-trusted-public-keys = [
      "cache.vedenemo.dev:RGHheQnb6rXGK5v9gexJZ8iWTPX6OcSeS56YeXYzOcg="
      "cache.ssrcdevops.tii.ae:oOrzj9iCppf+me5/3sN/BxEkp5SaFkHfKTPPZ97xXQk="
    ];
  };

  inputs = rec {
    ghafOS.url = "github:tiiuae/ghaf";
  };

  outputs = inputs @ {ghafOS, self, ...}: let
    # Retrieve inputs from Ghaf
    nixpkgs = ghafOS.inputs.nixpkgs;
    flake-utils = ghafOS.inputs.flake-utils;
    flake-parts = ghafOS.inputs.flake-parts;
    systems = with flake-utils.lib.system; [
      x86_64-linux
    ];

    lib = nixpkgs.lib.extend (final: _prev: {
      ghaf = import "${ghafOS}/lib" {
        inherit self;
        lib = final;
      };
    });

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
      ] ++ map generateHwConfig [
        (import ./hardware/fmo-os-rugged-laptop-7330.nix)
        (import ./hardware/fmo-os-rugged-laptop-7330-public.nix)
        (import ./hardware/fmo-os-rugged-tablet-7230.nix)
        (import ./hardware/fmo-os-rugged-tablet-7230-public.nix)
      ] ++ map generateInstConfig [
        (import ./installers/fmo-os-installer.nix)
        (import ./installers/fmo-os-installer-public.nix)
      ];

      flake.lib = lib;
    };
}
