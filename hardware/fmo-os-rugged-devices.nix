# Copyright 2022-2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
#
# fmo-os-rugged-devices computer -target
{
  sysconf = {
    name = "fmo-os-rugged-devices";
    ipaddr = "192.168.101.2";
    defaultgw = "192.168.101.1";
    release = "v1.1.0a";

    fmo-system = {
      RAversion = "v0.8.4";
    };

    device-info = ./device-info/rugged-devices.nix;

    systemPackages = [
      "vim"
      "tcpdump"
      "gpsd"
    ]; # systemPackages

    launchers = [
      {
        app = "terminal";
      }
      {
        app = "google-chrome";
        extraArgs = "192.168.101.11";
      }
      {
        app = "nmLauncher";
        extraArgs = "192.168.101.1 ghaf";
      }
    ]; # launchers;

    extraModules = [
      {
        # Add NVMe support into initrd to be able to boot from it
        boot.initrd.availableKernelModules = [ "nvme" "ahci" ];

        services = {
          fmo-psk-distribution-service-host = {
            enable = true;
          }; # services.fmo-psk-distribution-service-host
          fmo-dynamic-portforwarding-service-host = {
            enable = true;
            config-paths = {
              netvm = "/var/netvm/netconf/dpf.config";
            };
          }; # services.dynamic-portforwarding-service
          fmo-dynamic-device-passthrough-service-host = {
            enable = true;
          }; # services.dynamic-device-passthrough-service-host
          fmo-config = {
            enable = true;
          }; # services.fmo-config
          registration-agent-laptop = {
            enable = true;
          }; # services.registration-agent-laptop
          udev = {
            extraRules = ''
              # Add usb to kvm group
              SUBSYSTEM=="usb", ATTR{idVendor}=="0525", ATTR{idProduct}=="a4a2", GROUP+="kvm"
              SUBSYSTEM=="usb", ATTR{idVendor}=="1546", ATTR{idProduct}=="01a9", GROUP+="kvm"
            '';
          }; # services.udev
        }; # services
      }
    ]; # extraModules;

    vms = {
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
          users.users."ghaf".extraGroups = ["networkmanager"];
          networking = {
            useDHCP = false;
            nat = {
              enable = true;
              internalIPs = [ "192.168.101.0/24" ];
            }; # networking.nat
            networkmanager = {
              enable = true;
              unmanaged = [
                "ethint0"
              ];
            };
          }; # networking
          systemd.network.links."10-ethint0".extraConfig = "MTUBytes=1460";

          services = {
            udev = {
              extraRules = ''
                # Rename network devices
                SUBSYSTEM=="net", ACTION=="add", SUBSYSTEMS=="usb", ATTRS{idProduct}=="a4a2", ATTRS{idVendor}=="0525", NAME="mesh0"
                SUBSYSTEM=="net", ACTION=="add", DRIVERS=="e1000e", SUBSYSTEMS=="pci", ATTRS{vendor}=="0x8086", NAME="eth0"
              '';
            }; # services.udev

            avahi = {
              enable = true;
              nssmdns4 = true;
              reflector = true;
            }; # services.avahi

            fmo-psk-distribution-service-vm = {
              enable = true;
            }; # services.fmo-psk-distribution-service-vm

            dynamic-portforwarding-service = {
              enable = true;
              ipaddress = "192.168.100.12";
              ipaddress-path = "/etc/NetworkManager/system-connections/ip-address";
              config-path = "/etc/NetworkManager/system-connections/dpf.config";
              configuration = [
                {
                  dip = "192.168.101.11";
                  dport = "4222";
                  sport = "4222";
                  proto = "tcp";
                }
                {
                  dip = "192.168.101.11";
                  dport = "4222";
                  sport = "4222";
                  proto = "udp";
                }
                {
                  dip = "192.168.101.11";
                  dport = "7222";
                  sport = "7222";
                  proto = "tcp";
                }
                {
                  dip = "192.168.101.11";
                  dport = "7222";
                  sport = "7222";
                  proto = "udp";
                }
                {
                  dip = "192.168.101.11";
                  dport = "7422";
                  sport = "7422";
                  proto = "tcp";
                }
                {
                  dip = "192.168.101.11";
                  dport = "7423";
                  sport = "7423";
                  proto = "tcp";
                }
                {
                  dip = "192.168.101.11";
                  dport = "123";
                  sport = "123";
                  proto = "udp";
                }
                {
                  dip = "192.168.101.11";
                  dport = "123";
                  sport = "123";
                  proto = "tcp";
                }
              ];
            }; # services.portforwarding-service;
          }; # services

          microvm = {
            volumes = [
              {
                image = "/var/tmp/netvm_internal.img";
                mountPoint = "/var/lib/internal";
                size = 10240;
                autoCreate = true;
                fsType = "ext4";
              }
            ];# microvm.volumes

            shares = [
              {
                source = "/var/vms_shares/common";
                mountPoint = "/var/vms_share/common";
                tag = "common_share_netvm";
                proto = "virtiofs";
                socket = "common_share_netvm.sock";
              }
              {
                source = "/var/vms_shares/netvm";
                mountPoint = "/var/vms_share/host";
                tag = "netvm_share";
                proto = "virtiofs";
                socket = "netvm_share.sock";
              }
              {
                source = "/var/netvm/netconf";
                mountPoint = "/etc/NetworkManager/system-connections";
                tag = "netconf";
                proto = "virtiofs";
                socket = "netconf.sock";
              }
              {
                tag = "ssh-public-key";
                source = "/run/ssh-public-key";
                mountPoint = "/run/ssh-public-key";
              }
            ]; # microvm.shares
          }; # microvm

          fileSystems."/run/ssh-public-key".options = ["ro"];
          # For WLAN firmwares
          hardware.enableRedistributableFirmware = true;
        }]; # extraModules
      }; # netvm

      dockervm = {
        enable = true;
        name = "dockervm";
        macaddr = "02:00:00:01:01:02";
        ipaddr = "192.168.101.11";
        defaultgw = "192.168.101.1";
        systemPackages = [
          "vim"
          "tcpdump"
          "gpsd"
        ]; # systemPackages
        extraModules = [
        {
          users.users."ghaf".extraGroups = ["docker" "dialout"];
          systemd.network.links."10-ethint0".extraConfig = "MTUBytes=1460";
          microvm = {
            mem = 4096;
            vcpu = 2;
            volumes = [
              {
                image = "/var/tmp/dockervm_internal.img";
                mountPoint = "/var/lib/internal";
                size = 10240;
                autoCreate = true;
                fsType = "ext4";
              }
              {
                image = "/var/tmp/dockervm.img";
                mountPoint = "/var/lib/docker";
                size = 51200;
                autoCreate = true;
                fsType = "ext4";
              }
            ];# microvm.volumes

            shares = [
              {
                source = "/var/vms_shares/common";
                mountPoint = "/var/vms_share/common";
                tag = "common_share_dockervm";
                proto = "virtiofs";
                socket = "common_share_dockervm.sock";
              }
              {
                source = "/var/vms_shares/dockervm";
                mountPoint = "/var/vms_share/host";
                tag = "dockervm_share";
                proto = "virtiofs";
                socket = "dockervm_share.sock";
              }
              {
                source = "/var/fogdata";
                mountPoint = "/var/lib/fogdata";
                tag = "fogdatafs";
                proto = "virtiofs";
                socket = "fogdata.sock";
              }
              {
                tag = "ssh-public-key";
                source = "/run/ssh-public-key";
                mountPoint = "/run/ssh-public-key";
              }
            ]; # microvm.shares
          };# microvm
          fileSystems."/run/ssh-public-key".options = ["ro"];
          services = {
            fmo-hostname-service = {
              enable = true;
              hostname-path = "/var/lib/fogdata/hostname";
            }; # services.fmo-hostnam-service
            fmo-psk-distribution-service-vm = {
              enable = true;
            }; # services.fmo-psk-distribution-service-vm
            fmo-dynamic-device-passthrough = {
              enable = true;
              devices = [
                {
                  bus = "usb";
                  vendorid = "1546";
                  productid = "01a9";
                }
              ];
            }; # services.fmo-dynamic-device-passthrough
            fmo-dci = {
              enable = true;
              compose-path = "/var/lib/fogdata/docker-compose.yml";
              update-path = "/var/lib/fogdata/docker-compose.yml.new";
              backup-path = "/var/lib/fogdata/docker-compose.yml.backup";
              pat-path = "/var/lib/fogdata/PAT.pat";
              preloaded-images = "tii-offline-map-data-loader.tar.gz";
              docker-url = "cr.airoplatform.com";
              docker-url-path = "/var/lib/fogdata/cr.url";
            }; # services.fmo-dci
            avahi = {
              enable = true;
              nssmdns4 = true;
            }; # services.avahi
            registration-agent-laptop = {
              enable = true;
              run_on_boot = true;
              certs_path = "/var/lib/fogdata/certs";
              config_path = "/var/lib/fogdata";
              token_path = "/var/lib/fogdata";
              hostname_path = "/var/lib/fogdata";
              ip_path = "/var/lib/fogdata";
              post_install_path = "/var/lib/fogdata/certs";
            }; # services.registration-agent-laptop
          }; # services
          networking.firewall.enable = false;
        }]; # extraModules
      }; # dockervm
    }; # vms
  }; # system
}
