# Copyright 2022-2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
#
# Example -- here is an example of OS with 3 VMs
# If you need to describe a new OS configuration - start here
{
  # system and host description
  sysconf = {
    name = "example";
    description = "example OS with 3 VMs";
    systemPackages = [
      "vim"
      "tcpdump"
    ]; # systemPackages

    # Optional
    # File containing information about VMs and pci-devices passed through
    #  device-info = ./device-info/rugged-devices.nix;

    # VMs description
    vms = {
      # NetVM -- the network VM
      netvm = {
        enable = true;
        name = "netvm";
        macaddr = "02:00:00:01:01:01";
        ipaddr = "192.168.101.1";
        systemPackages = [
          "vim"
          "tcpdump"
        ]; # systemPackages
        extraModules = [
        {
          networking = {
            nat.enable = true;
            wireless = {
              enable = true;
            };
            networkmanager = {
              enable = true;
              unmanaged = [
                "ethint0"
              ];
            };
          }; # networking

          microvm.devices = [
            {
              bus = "pci";
              # Add yours network device here
              path = "0000:72:00.0";
            }
          ]; # microvm.devices

          # For WLAN firmwares
          hardware.enableRedistributableFirmware = true;
        }]; # extraModules
      }; # netvm

      # The docker apps VM
      dockervm = {
        enable = true;
        name = "dockervm";
        macaddr = "02:00:00:01:01:02";
        ipaddr = "192.168.101.11";
        defaultgw = "192.168.101.1";
        systemPackages = [
          "vim"
          "tcpdump"
        ]; # systemPackages
        extraModules = [
        {
          microvm = {
            mem = 4096;
            vcpu = 2;
            volumes = [{
              image = "/var/tmp/dockervm.img";
              mountPoint = "/var/lib/docker";
              size = 51200;
              autoCreate = true;
              fsType = "ext4";
            }];# microvm.volumes
            shares = [
              {
                source = "/var/datashare";
                mountPoint = "/var/lib/datashare";
                tag = "datasharefs";
                proto = "virtiofs";
                socket = "datashare.sock";
              }
            ]; # microvm.shares
          };# microvm
         networking.firewall.enable = false;
        }]; # extraModules
      }; # dockervm

      # Dummy VM
      dummyvm = {
        enable = true;
        name = "dummyvm";
        macaddr = "02:00:00:01:01:03";
        ipaddr = "192.168.101.12";
        defaultgw = "192.168.101.1";
        extraModules = [
        {
         networking.firewall.enable = false;
        }]; # extraModules
      }; # dummyvm
    }; # vms
  }; # system
}
