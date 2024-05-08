# Copyright 2022-2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
#
# This overlay customizes python311 - see comments for details
#
(final: prev: {
    python311 = prev.python311.override {
        packageOverrides = (python-self: python-super: {
        afdko =  python-super.afdko.overridePythonAttrs (oldAttrs: {
            disabledTests = [
              "test_alt_missing_glyph"
            ];
        });
        });
    };
})
