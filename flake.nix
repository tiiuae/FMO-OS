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

  outputs = {
    self,
    ghafOS,
  }: let
    # Retrieve inputs from Ghaf
    nixpkgs = ghafOS.inputs.nixpkgs;
    flake-utils = ghafOS.inputs.flake-utils;
    nixos-generators = ghafOS.inputs.nixos-generators;
    nixos-hardware = ghafOS.inputs.nixos-hardware;
    microvm = ghafOS.inputs.microvm;

    systems = with flake-utils.lib.system; [
      x86_64-linux
    ];

    lib = nixpkgs.lib.extend (final: _prev: {
      ghaf = import "${ghafOS}/lib" {
        inherit self;
        lib = final;
      };
    });

    generateHwConfig = import ./config-processor-hardware.nix {inherit nixpkgs ghafOS self nixos-hardware nixos-generators lib microvm;};
    generateInstConfig = import ./config-processor-installers.nix {inherit nixpkgs ghafOS self nixos-hardware nixos-generators lib microvm;};
  in
    # Combine list of attribute sets together
    lib.foldr lib.recursiveUpdate {} ([
      (flake-utils.lib.eachSystem systems (system: let
        pkgs = nixpkgs.legacyPackages.${system};
      in {
        hydraJobs = {
          inherit (self) packages;
        };

        formatter = pkgs.alejandra;
      }))
    ]
    ++ map generateHwConfig [
      (import ./hardware/fmo-os-rugged-laptop-7330.nix)
      (import ./hardware/fmo-os-rugged-laptop-7330-public.nix)
      (import ./hardware/fmo-os-rugged-tablet-7230.nix)
      (import ./hardware/fmo-os-rugged-tablet-7230-public.nix)
    ]
    ++ map generateInstConfig [
      (import ./installers/fmo-os-installer.nix)
      (import ./installers/fmo-os-installer-public.nix)
    ]);
}
