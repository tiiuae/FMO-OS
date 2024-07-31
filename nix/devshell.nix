# Copyright 2022-2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{inputs, ...}: {
  perSystem = {
    lib,
    pkgs,
    system,
    ...
  }: let
    kernelShellPkgs = with pkgs; [
      ncurses
      pkg-config
    ];
    #++ (inputs.ghafOS.packages.${system}.kernel-hardening-checker);

    devShellPkgs = with pkgs;
      [
        alejandra
        git
        mdbook
        nix
        nixci
        nixos-rebuild
        nix-output-monitor
        nix-tree
        reuse
        statix
      ]
      ++ (lib.optional (system != "riscv64-linux") pkgs.cachix);

    mkDevShell = {
      system ? "x86_64-linux",
      shellName ? null,
      kernelPackage ? null,
      extraPackages ? [],
      shellHook ? "",
    }:
      pkgs.mkShell {
        name =
          if shellName != null
          then builtins.toString shellName
          else if kernelPackage != null
          then "FMO-OS kernel devshell (${system})"
          else "FMO-OS devshell (${system})";
        packages =
          devShellPkgs
          ++ (
            if kernelPackage != null
            then kernelShellPkgs
            else []
          )
          ++ extraPackages;

        inputsFrom =
          if kernelPackage != null
          then [kernelPackage]
          else [];

        shellHook =
          if kernelPackage != null
          then ''
                export src=${kernelPackage.src}
            if [ -d "$src" ]; then
              # Jetpack's kernel named "source-patched" or likewise, workaround it
              linuxDir=$(stripHash ${kernelPackage.src})
            else
              linuxDir="linux-${kernelPackage.version}"
            fi
            if [ ! -d "$linuxDir" ]; then
              unpackPhase
              patchPhase
            fi
            cd "$linuxDir"
            # extra post-patching for NVidia
            ${shellHook}

            export PS1="[FMO-OS-kernel-devshell(${system}):\w]$ "
          ''
          else ''
            ${shellHook}
            export PS1="[FMO-OS-devshell-(${system}):\w]$ "
          '';

        # use "eval $checkPhase" - see https://discourse.nixos.org/t/nix-develop-and-checkphase/25707
        #checkPhase = "cp ../modules/hardware/${platform}/kernel/configs/ghaf_host_hardened_baseline-${arch} ./.config && make -j$(nproc)";
      };
  in {
    devShells.kernel = mkDevShell {
      inherit system;
      kernelPackage = pkgs.linux;
    };

    devShells.default = mkDevShell {
      inherit system;
      #extraPackages = [inputs'.nix-fast-build.packages.default];
    };

    # TODO Add pre-commit.devShell (needs to exclude RiscV)
    # https://flake.parts/options/pre-commit-hooks-nix
  };
}
