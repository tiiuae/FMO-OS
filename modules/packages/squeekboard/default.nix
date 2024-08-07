# Copyright 2022-2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
(final: _prev: {
  squeekboard = _prev.squeekboard.overrideAttrs (oldAttrs: {
    postPatch = oldAttrs.postPatch or "" + ''
      ${_prev.coreutils}/bin/cp -rf ${./us_wide.yaml} data/keyboards/terminal/us_wide.yaml
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
  squeekboard-control = final.callPackage ./squeekboard.nix {pkgs=final;};
})
