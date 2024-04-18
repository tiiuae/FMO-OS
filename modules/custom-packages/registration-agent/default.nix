# Copyright 2022-2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
(final: _prev: {
  registration-agent-laptop = final.callPackage ./registration-agent-laptop-with-env.nix {
    pkgs = final;
    env_path = "/var/fogdata";
  };
})
