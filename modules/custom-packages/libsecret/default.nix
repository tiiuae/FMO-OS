# Copyright 2022-2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
(final: _prev: {
  libsecret = _prev.libsecret.overrideAttrs (old : {
      doCheck = false;
      doInstallCheck = false;
  });
})
