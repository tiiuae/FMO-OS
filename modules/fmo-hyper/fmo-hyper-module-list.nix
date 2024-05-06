# Copyright 2022-2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
#
#
{ targetconf }:
let
  fmo-hyper-modules = 
  [
    ./fmo-config
  ];
in
  map (module: (import module {inherit targetconf;})) fmo-hyper-modules

