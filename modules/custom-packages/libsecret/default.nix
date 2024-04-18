# Copyright 2022-2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
(_final: _prev: {
  libsecret = _prev.libsecret.overrideAttrs (_old: {
    doCheck = false;
    doInstallCheck = false;
  });
})
