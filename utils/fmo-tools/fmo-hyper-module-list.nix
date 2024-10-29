# Copyright 2022-2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
#
#
(targetconf :
let
  fmo-tools-list =
  [
    ./fmo-config
  ];
in
  map (module: (import module {inherit targetconf;})) fmo-tools-list
)
