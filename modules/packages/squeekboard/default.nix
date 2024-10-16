# Copyright 2022-2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
(final: prev: let
  pkgSrc = prev.fetchFromGitLab {
    domain = "gitlab.gnome.org";
    group = "World";
    owner = "Phosh";
    repo = "${prev.squeekboard.pname}";
    rev = "v${prev.squeekboard.version}";
    hash = "sha256-ZVSnLH2wLPcOHkU2pO0BgIdGmULMNiacIYMRmhN+bZ8=";
  };
in {
  squeekboard = prev.squeekboard.overrideAttrs (oldAttrs: {
    postPatch =
      oldAttrs.postPatch
      or ""
      + ''
        ${prev.coreutils}/bin/cp -rf ${./us_wide.yaml} data/keyboards/terminal/us_wide.yaml
        ${prev.coreutils}/bin/cp -rf ${./fi_wide.yaml} data/keyboards/terminal/fi_wide.yaml
      '';
    postInstall = ''
      mkdir -p $out/share/dbus-1/services
      cat <<END > $out/share/dbus-1/services/sm.puri.OSK0.service
      [D-BUS Service]
      Name=sm.puri.OSK0
      Exec=$out/bin/squeekboard
      END
    '';
  });
  squeekboard-control = final.callPackage ./squeekboard.nix {pkgs = final;};
})
