# Copyright 2022-2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
(final: _prev: {
  nwg-panel = _prev.nwg-panel.overrideAttrs (oldAttrs : {
    postInstall = oldAttrs.postInstall + ''
      wrapProgram $out/bin/nwg-panel --add-flags "-s /etc/xdg/nwg-panel/style.css -c /etc/xdg/nwg-panel/config"
    '';
  });
})
