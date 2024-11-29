# Copyright 2022-2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
#
# fmo-os-rugged-tablet-7230 computer -target
{
  sysconf = {
    name = "fmo-os-rugged-tablet-7230";
    ipaddr = "192.168.101.2";
    defaultgw = "192.168.101.1";
    release = "v1.1.0a";

    fmo-system = {
      RAversion = "v0.8.4";
    };
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
          }; # fmo-config
          registration-agent-laptop = {
            enable = true;
          }; # services.registration-agent-laptop
          udev = {
            extraRules = ''
              # Add usb to kvm group
              SUBSYSTEM=="usb", ATTR{idVendor}=="0525", ATTR{idProduct}=="a4a2", GROUP+="kvm"
              SUBSYSTEM=="usb", ATTR{idVendor}=="1546", ATTR{idProduct}=="01a9", GROUP+="kvm"
              SUBSYSTEM=="usb", ATTR{idVendor}=="1050", ATTR{idProduct}=="0407", GROUP+="kvm"
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
              nssmdns = true;
              reflector = true;
            }; # services.avahi

            fmo-psk-distribution-service-vm = {
              enable = true;
            }; # fmo-psk-distribution-service-vm

            dynamic-portforwarding-service = {
              enable = true;
              ipaddress = "192.168.100.12";
              ipaddress-path = "/etc/NetworkManager/system-connections/ip-address";
              config-path = "/etc/NetworkManager/system-connections/dpf.config";
              configuration = [
                # dockervm
                { dip = "192.168.101.11"; dport = "4222"; sport = "4222"; proto = "tcp"; }
                { dip = "192.168.101.11"; dport = "4222"; sport = "4222"; proto = "udp"; }
                { dip = "192.168.101.11"; dport = "7222"; sport = "7222"; proto = "tcp"; }
                { dip = "192.168.101.11"; dport = "7222"; sport = "7222"; proto = "udp"; }
                { dip = "192.168.101.11"; dport = "7422"; sport = "7422"; proto = "tcp"; }
                { dip = "192.168.101.11"; dport = "7423"; sport = "7423"; proto = "tcp"; }
                { dip = "192.168.101.11"; dport = "123"; sport = "123"; proto = "udp"; }
                { dip = "192.168.101.11"; dport = "123"; sport = "123"; proto = "tcp"; }
                # adaptervm
                { dip = "192.168.101.12"; dport = "22223"; sport = "22223"; proto = "udp"; }
                { dip = "192.168.101.12"; dport = "10023"; sport = "10023"; proto = "udp"; }
                { dip = "192.168.101.12"; dport = "10013"; sport = "10013"; proto = "udp"; }
                # adaptervm NATS reservations; max five drones, two ports each
                { dip = "192.168.101.12"; dport = "4222"; sport = "4222"; proto = "tcp"; }
                { dip = "192.168.101.12"; dport = "4223"; sport = "4223"; proto = "tcp"; }
                { dip = "192.168.101.12"; dport = "4224"; sport = "4224"; proto = "tcp"; }
                { dip = "192.168.101.12"; dport = "4225"; sport = "4225"; proto = "tcp"; }
                { dip = "192.168.101.12"; dport = "4226"; sport = "4226"; proto = "tcp"; }
                { dip = "192.168.101.12"; dport = "8222"; sport = "8222"; proto = "tcp"; }
                { dip = "192.168.101.12"; dport = "8223"; sport = "8223"; proto = "tcp"; }
                { dip = "192.168.101.12"; dport = "8224"; sport = "8224"; proto = "tcp"; }
                { dip = "192.168.101.12"; dport = "8225"; sport = "8225"; proto = "tcp"; }
                { dip = "192.168.101.12"; dport = "8226"; sport = "8226"; proto = "tcp"; }
              ];
            }; # services.dynamic-portforwarding-service
          }; # services

          microvm = {
            devices = [
              {
                bus = "pci";
                path = "0000:00:14.3";
              }
            ]; # microvm.devices

            # WAR: Default microvm's way to passthrough usb devices is not working
            # Lets use qemu.extraArgs for that
            qemu.extraArgs = [
              "-usb"
              "-device"
              "usb-host,vendorid=0x0525,productid=0xa4a2"
            ]; # microvm.qemu.extraArgs

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
            # WAR: Default microvm's way to passthrough usb devices is not working
            # Lets use qemu.extraArgs for that
            qemu.extraArgs = [
              "-usb"
              "-device"
              "usb-host,vendorid=0x1546,productid=0x01a9"
            ]; # microvm.qemu.extraArgs
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
            }; # fmo-psk-distribution-service-vm
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
              nssmdns = true;
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

      adaptervm = {
        enable = true;
        name = "adaptervm";
        macaddr = "02:00:00:01:01:03";
        ipaddr = "192.168.101.12";
        defaultgw = "192.168.101.1";
        systemPackages = [
          "croc"
          "gpsd"
          "jq"
          "libp11"
          "mustache-go"
          "opensc"
          "openssl"
          "pkcs11-provider"
          "p11-kit"
          "tcpdump"
          "terminator"
          "vim"
          "yubico-piv-tool"
        ]; # systemPackages
        extraModules = [
        {
          users.users."ghaf".extraGroups = ["docker" "dialout"];
          systemd.network.links."10-ethint0".extraConfig = "MTUBytes=1460";
          microvm = {
            mem = 4096;
            vcpu = 2;
            # WAR: Default microvm's way to passthrough usb devices is not working
            # Lets use qemu.extraArgs for that
            qemu.extraArgs = [
              "-usb"
              "-device"
              "usb-host,vendorid=0x1050,productid=0x0407"
            ]; # microvm.qemu.extraArgs
            volumes = [
              {
                image = "/var/tmp/adaptervm_internal.img";
                mountPoint = "/var/lib/internal";
                size = 10240;
                autoCreate = true;
                fsType = "ext4";
              }
              {
                image = "/var/tmp/adaptervm.img";
                mountPoint = "/var/lib/adapter";
                size = 51200;
                autoCreate = true;
                fsType = "ext4";
              }
            ];# microvm.volumes
            shares = [
              {
                source = "/var/vms_shares/common";
                mountPoint = "/var/vms_share/common";
                tag = "common_share_adaptervm";
                proto = "virtiofs";
                socket = "common_share_adaptervm.sock";
              }
              {
                source = "/var/vms_shares/adaptervm";
                mountPoint = "/var/vms_share/host";
                tag = "adaptervm_share";
                proto = "virtiofs";
                socket = "adaptervm_share.sock";
              }
              {
                source = "/var/fogdata";
                mountPoint = "/var/lib/fogdata";
                tag = "fogdatafs";
                proto = "virtiofs";
                socket = "fogdata-adaptervm.sock";
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
            udev = {
              extraRules = ''
                # Add usb to kvm group
                SUBSYSTEM=="usb", ATTR{idVendor}=="1050", ATTR{idProduct}=="0407", MODE="0666"
              '';
            }; # services.udev
            fmo-adapter-yubikey-hotplug-service = {
              enable = true;
            }; # services.fmo-adapter-yubikey-hotplug-service
            fmo-hostname-service = {
              enable = true;
              hostname-override = "adaptervm";
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
              nssmdns = true;
            }; # services.avahi
            pcscd.enable = true;
          }; # services
          networking.firewall.enable = false;
        }]; # extraModules
      }; # adaptervm
    }; # vms
  }; # system
}
