# Copyright 2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
#
# Services for FMO
#
{
  imports = [
    ./dci-service
    ./hostname-service
    ./portforwarding-service
    ./dynamic-portforwarding-service
    ./dynamic-portforwarding-service-host
    ./psk-distribution-host
    ./psk-distribution-vm
    ./registration-agent-laptop
    ./dynamic-device-passthrough-services
    ./dynamic-device-passthrough-services-host
  ];
}
