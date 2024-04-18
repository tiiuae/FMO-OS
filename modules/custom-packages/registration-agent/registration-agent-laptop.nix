# Copyright 2022-2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{pkgs}: let
  buildGo121Module = pkgs.darwin.apple_sdk_11_0.callPackage ../../../utils/golang/module.nix {
    go = go_1_21;
  };
  go_1_21 = pkgs.darwin.apple_sdk_11_0.callPackage ../../../utils/golang/1.21.nix {
    inherit (pkgs.darwin.apple_sdk_11_0.frameworks) Foundation Security;
    inherit buildGo121Module;
  };
in
  buildGo121Module {
    name = "registration-agent-laptop";
    src = builtins.fetchGit {
      url = "git@github.com:tiiuae/registration-agent-laptop.git";
      rev = "2f904867b98c65d38561e2447183109a7c68ba0d";
      ref = "refs/heads/main";
    };
    tags = ["prod"];
    patches = [./remove-test.patch];
    vendorSha256 = "sha256-9/twQyt6SVXWTRypt1FIWsRQxQEWFBkdi8eR+/xYNqg==";
    proxyVendor = true;

    postInstall = ''
      mv $out/bin/registration-agent-laptop $out/bin/registration-agent-laptop-orig
    '';
    # ...
  }
