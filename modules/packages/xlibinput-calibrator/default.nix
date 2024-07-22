# Copyright 2022-2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
(final: _prev: {
  xlibinput-calibrator = _prev.xlibinput-calibrator.overrideAttrs (oldAttrs: {
    version = "0.13.1";
    hash = "sha256-iHQckczBfZBonAwgDqGGSe4jfGUBfaMV/dlo+o1Mm8A=";
  });
})
