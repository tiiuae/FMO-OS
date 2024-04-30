# Copyright 2022-2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
#
# libsecret upstream fixed
#
(final: prev: {
  libsecret = prev.libsecret.overrideAttrs (old : {
      doCheck = false;
      doInstallCheck = false;
  });
})
