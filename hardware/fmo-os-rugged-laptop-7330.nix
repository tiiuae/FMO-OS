# Copyright 2022-2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
#
# fmo-os-rugged-laptop-7330 computer -target
{
  sysconf = {
    name = "fmo-os-rugged-laptop-7330";
    ipaddr = "192.168.101.2";
    defaultgw = "192.168.101.1";

    systemPackages = [
      "vim"
      "tcpdump"
      "gpsd"
      "chromium"
    ]; # systemPackages

    launchers = [
      {
        app = "terminal";
      }
      {
        app = "chromium";
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
          };
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
            };

            portforwarding-service = {
              enable = true;
              ipaddress = "192.168.100.12";
              ipaddress-path = "/etc/NetworkManager/system-connections/ip-address";
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
              ];
            }; # services.portforwarding-service;
          }; # services

          microvm = {
            devices = [
              {
                bus = "pci";
                path = "0000:72:00.0";
              }
              {
                bus = "pci";
                path = "0000:00:1f.0";
              }
              {
                bus = "pci";
                path = "0000:00:1f.3";
              }
              {
                bus = "pci";
                path = "0000:00:1f.4";
              }
              {
                bus = "pci";
                path = "0000:00:1f.5";
              }
              {
                bus = "pci";
                path = "0000:00:1f.6";
              }
              {
                bus = "usb";
                path = "vendorid=0x0525,productid=0xa4a2";
              }
            ]; # microvm.devices

            shares = [
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
            devices = [
              {
                bus = "usb";
                path = "vendorid=0x1546,productid=0x01a9";
              }
            ]; # microvm.devices
            volumes = [{
              image = "/var/tmp/dockervm.img";
              mountPoint = "/var/lib/docker";
              size = 51200;
              autoCreate = true;
              fsType = "ext4";
            }];# microvm.volumes
            shares = [
              {
                source = "/var/fogdata";
                mountPoint = "/var/lib/fogdata";
                tag = "fogdatafs";
                proto = "virtiofs";
                socket = "fogdata.sock";
              }
            ]; # microvm.shares
          };# microvm
          services = {
            fmo-hostname-service = {
              enable = true;
              hostname-path = "/var/lib/fogdata/hostname";
            }; # services.fmo-hostnam-service
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
