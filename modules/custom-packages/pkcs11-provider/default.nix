# Copyright 2022-2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
(final: _prev: {
  pkcs11-provider = _prev.callPackage ./pkcs11-provider.nix {};
})
