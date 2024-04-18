# Copyright 2022-2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{
  lib,
  pkgs,
  system,
  treefmt-nix,
  ...
}: let
  configTemplate = {
    # Which 'treefmt' package to use.
    package = pkgs.treefmt;

    # Used to find the project root.
    projectRootFile = "flake.nix";

    # Reference:
    # https://github.com/numtide/treefmt-nix?tab=readme-ov-file#flakes
    programs = {
      # Nix formatters/linters.
      # - Alejandra Nix formatter: https://github.com/kamadorueda/alejandra
      # - Removes dead Nix code: https://github.com/astro/deadnix
      # - Prevent Nix anti-patterns: https://github.com/nerdypepper/statix
      alejandra.enable = true;
      deadnix.enable = true;
      statix.enable = true;

      # Python formatters/linters.
      #
      # It was found out that the best outcome comes from running multiple tools.
      # Ruff is a Python formatter written in Rust (30x faster than Black), which
      # also provides additional linting. Do not set 'ruff.format = true',
      # because then it won't complain about linting errors. The default mode
      # is the check mode.
      #
      # - Black, the classic Python formatter: https://github.com/psf/black
      # - isort, Python import sorter: https://pycqa.github.io/isort/
      # - Ruff, Python formatter written in Rust: https://github.com/astral-sh/ruff
      black.enable = true;
      isort.enable = true;
      ruff.enable = true;

      # Bash formatters/linters.
      # - Shellcheck lints shell scripts: https://github.com/koalaman/shellcheck
      # - Shfmt formats shell scripts: https://github.com/mvdan/sh
      shellcheck.enable = true;
      shfmt.enable = true;
    };

    # Set Ruff to automatically fix linting and formatting errors where possible.
    settings.formatter.ruff.options = ["check" "--fix"];

    # Additional shfmt flags.
    settings.formatter.shfmt.options = ["-bn" "-ci" "-sr"];
  };

  treeFmtConfig = lib.genAttrs [system] (_system: treefmt-nix.lib.evalModule pkgs configTemplate);
in {
  inherit (treeFmtConfig.${system}) config;
}
