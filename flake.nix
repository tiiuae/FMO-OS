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

    # Format all the things with treefmt.
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "ghafOS/nixpkgs";
    };
  };

  outputs = {
    self,
    ghafOS,
    treefmt-nix,
    ...
  }: let
    # Retrieve inputs from Ghaf
    inherit (ghafOS.inputs) nixpkgs;
    inherit (ghafOS.inputs) flake-utils;
    inherit (ghafOS.inputs) nixos-generators;
    inherit (ghafOS.inputs) microvm;

    systems = with flake-utils.lib.system; [
      x86_64-linux
    ];

    lib = nixpkgs.lib.extend (final: _prev: {
      ghaf = import "${ghafOS}/lib" {
        inherit self;
        lib = final;
      };
    });

    generateHwConfig = import ./config-processor-hardware.nix {inherit ghafOS nixos-generators lib microvm;};
    generateInstConfig = import ./config-processor-installers.nix {inherit nixpkgs ghafOS self nixos-generators lib;};
  in
    # Combine list of attribute sets together
    lib.foldr lib.recursiveUpdate {} ([
        (flake-utils.lib.eachSystem systems (system: let
          pkgs = nixpkgs.legacyPackages.${system};

          # Evaluate treefmt config for each system
          treefmt = import ./treefmt.nix {inherit self lib pkgs system treefmt-nix;};
        in {
          formatter = treefmt.config.build.wrapper;

          hydraJobs = {
            packages = {
              x86_64-linux = {
                inherit (self.packages.x86_64-linux) fmo-os-installer-public-debug;
                inherit (self.packages.x86_64-linux) fmo-os-installer-public-release;
                inherit (self.packages.x86_64-linux) fmo-os-rugged-laptop-7330-public-debug;
                inherit (self.packages.x86_64-linux) fmo-os-rugged-laptop-7330-public-release;
                inherit (self.packages.x86_64-linux) fmo-os-rugged-tablet-7230-public-debug;
                inherit (self.packages.x86_64-linux) fmo-os-rugged-tablet-7230-public-release;
              };
            };
          };
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
