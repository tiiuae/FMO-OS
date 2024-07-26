# Copyright 2022-2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{
  stdenv,
  lib,
  rustPlatform,
  fetchFromGitHub,
}:
rustPlatform.buildRustPackage rec {
  pname = "calibrate-touchscreen";
  version = "0.1.0";

  src = fetchFromGitHub {
    owner = "AlanGriffiths";
    repo = "libinput";
    rev = "844319716dc2c758a4099fe81511eda818681139";

    # This utility/package is part of `libinput` snap package, and we only
    # need the sources for `calibrate-touchscreen` so do a sparse checkout.
    sparseCheckout = [
      "${pname}"
    ];
    hash = "sha256-7sa4hHPZJzctvkg4D+acARw39+WTQh2y7cl6LlwpvT8=";
  };

  cargoHash = "sha256-3BYJ25Dxeust3+8jsvXZa9XHpYnzJtP9iNarJiMGRxU=";

  # Point to correct source directory
  sourceRoot = "source/${pname}";

  # No tests defined
  doCheck = false;
  doInstallCheck = false;

  meta = with lib; {
    description = "A utility for calibrating touchscreen on Wayland";
    longDescription = ''
      ${pname} is a helper utility for calibrating touchscreen on Wayland.
      See https://mir-server.io/docs/howto-calibrate-a-touchscreen-device
    '';
    homepage = "https://github.com/AlanGriffiths/libinput";
    license = licenses.asl20;
    platforms = platforms.all;
  };
}
