# Copyright 2022-2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
(final: _prev: {
  nwg-panel = _prev.nwg-panel.overrideAttrs (oldAttrs : {
    version = "0.9.27";
    src = _prev.fetchFromGitHub {
      owner = "nwg-piotr";
      repo = "nwg-panel";
      rev = "refs/tags/v0.9.27";
      hash = "sha256-GCaqFqoZ7lfyE3VD3Dgz8jVt9TtUq3XVzVeI6g3SO5E=";
     };
    buildInputs = oldAttrs.buildInputs ++ [ _prev.playerctl _prev.makeWrapper ];
    preFixup = with _prev; ''
      makeWrapperArgs+=(
        "''${gappsWrapperArgs[@]}"
        --prefix XDG_DATA_DIRS : "$out/share"
        --prefix PATH : "${lib.makeBinPath [ brightnessctl nwg-menu pamixer pulseaudio sway systemd ]}"
      )
    '';
    postInstall = ''
      mkdir -p $out/share/{applications,pixmaps}
      cp $src/nwg-panel-config.desktop nwg-processes.desktop $out/share/applications/
      cp $src/nwg-shell.svg $src/nwg-panel.svg nwg-processes.svg $out/share/pixmaps/
      wrapProgram $out/bin/nwg-panel --add-flags "-s /etc/xdg/nwg-panel/style.css -c /etc/xdg/nwg-panel/config"
    '';
  });
})
