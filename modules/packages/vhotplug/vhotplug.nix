# Copyright 2022-2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{
  python3Packages,
  pkgs,
  fetchFromGitHub,
}: let
  qemuqmp = pkgs.callPackage ./qemuqmp.nix {};
in
  python3Packages.buildPythonApplication rec {
    pname = "vhotplug";
    version = "0.1";

    propagatedBuildInputs = [
      python3Packages.pyudev
      python3Packages.psutil
      qemuqmp
    ];

    doCheck = false;
    patches = [ ./reload-config.patch ];
    src = fetchFromGitHub {
      owner = "tiiuae";
      repo = "vhotplug";
      rev = "fd05361ed893d06cdb5ac4a538c171e4a86b6f5a";
      hash = "sha256-6fl5xeSpcIIBKn3dZUAEHiNRRpn9LbYC4Imap5KBH2M=";
    };
  }
