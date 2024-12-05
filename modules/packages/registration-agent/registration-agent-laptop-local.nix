# Copyright 2022-2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0

{pkgs,lib}:
pkgs.buildGoModule {
  name = "registration-agent-laptop";
  src = ./RA-local;
  tags = [ "prod" ];
  patches = [./remove-test.patch];
  vendorHash = ''
    sha256-18p7l1otlviZNlM0UlCgW/US5YckBYcY/OEJoJIsIM0=
    '';
  proxyVendor=true;
  postInstall = ''
    mv $out/bin/registration-agent-laptop $out/bin/registration-agent-laptop-orig
  '';
}
