# Copyright 2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
#
# Services for FMO
#
{
  imports = [
    ./dci-service
    ./hostname-service
    ./dynamic-portforwarding-service
    ./dynamic-device-passthrough-service
    ./psk-distribution-vm
    ./registration-agent-laptop    
  ];
}
