# Copyright 2022-2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0

{pkgs,lib}:
pkgs.buildGoModule {
  name = "registration-agent-laptop";
  src = builtins.fetchGit {
    url = "git@github.com:tiiuae/registration-agent-laptop.git";
    rev = "8df9034641431aaee66eceff0ebb5257e2e4244e";
    ref = "refs/heads/main";
  };
  tags = [ "prod" ];
  patches = [./remove-test.patch];
  vendorHash = "sha256-aChlfSPo9E2ktzkeWZSWEsDh3lbcQvfuA7E2i8q36gU=";
  proxyVendor=true;
  postInstall = ''
    mv $out/bin/registration-agent-laptop $out/bin/registration-agent-laptop-orig
  '';
}
