# Copyright 2022-2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
(final: _prev: {
  lisgd = _prev.lisgd.overrideAttrs (oldAttrs: {
        postPatch = oldAttrs.postPatch or "" + ''
          cp ${./config} config.def.h
        '';
     });
})
