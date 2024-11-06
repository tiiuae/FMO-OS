# FMO-OS
* Operating System for Flight and Mission Operations devices
* A ghaf-based operating system designed specifically for FMO devices
* Currently support: Dell Latitude 7230 Rugged Extreme Tablet & Dell Latitude 7330 Rugged Extreme Laptop

# Table of Contents
1. [How to compile](#how-to-compile)
1. [Using cachix to build speed up](#using-cachix-to-build-speed-up)
1. [How to modify or add new hardware](#how-to-modify-or-add-new-hardware)
1. [Hardware description file structure](#hardware-description-file-structure)
1. [How to add a new virtual machine for existing HW](#how-to-add-a-new-virtual-machine-for-existing-HW)
1. [Ghaf documentation links](#ghaf-documentation-links)
1. [Release notes](#release-notes)

# How to compile
- Clone the project:
  ```bash
  $ git clone https://github.com/tiiuae/FMO-OS.git
  ```
- Move to source folder
  ```bash
  $ cd FMO-OS
  ```
- Install NIX (you also can make it manually or use NIX-OS, then you may skip this part):
  ```bash
  $ bash .github/actions/build-action/install_nix.sh
  ...
  ...
  [ 1 ]
  Nix won't work in active shell sessions until you restart them.
  ```
- No you need to restart your session:
```bash
$ exit
```
- Reloging your session and go to the source folder again:
```bash
$ cd FMO-OS
```
- Check build targets:
```bash
$ nix flake show
...
...
└───packages
    └───x86_64-linux
        ├───fmo-os-installer-debug: package 'nixos.iso'
        ├───fmo-os-installer-debug-compressed: package 'nixos.iso'
        ├───fmo-os-installer-public-debug: package 'nixos.iso'
        ├───fmo-os-installer-public-debug-compressed: package 'nixos.iso'
        ├───fmo-os-installer-public-release: package 'nixos.iso'
        ├───fmo-os-installer-public-release-compressed: package 'nixos.iso'
        ├───fmo-os-installer-release: package 'nixos.iso'
        ├───fmo-os-installer-release-compressed: package 'nixos.iso'

```
- Build FMO-OS installer image (you need to have github ssh keys installed on your system):
```bash
$ nix build -L .#fmo-os-installer-debug
```

# Using cachix to build speed up
- You may use binary $ to speed up your builds
- Install cachix:
```bash
$ nix-env -iA cachix -f https://cachix.org/api/v1/install
```
- Authenticate:
```bash
$ cachix authtoken {put_your_token here}
```
- Use $ix to build:
```bash
$ cachix use fmo-os
$ nix build -L .#fmo-os-installer-debug
```

# How to modify or add new hardware

All work with hardware starts from adding/modifying HW description files:
```bash
$ $ ls -l hardware/
total 36
-rw-rw-r-- 1 vboxuser vboxuser  2764 Nov  6 11:59 example.nix
-rw-rw-r-- 1 vboxuser vboxuser   769 Nov  6 11:59 fmo-os-rugged-laptop-7330-public.nix
-rw-rw-r-- 1 vboxuser vboxuser 12068 Nov  6 11:59 fmo-os-rugged-laptop-7330.nix
-rw-rw-r-- 1 vboxuser vboxuser   763 Nov  6 11:59 fmo-os-rugged-tablet-7230-public.nix
-rw-rw-r-- 1 vboxuser vboxuser 11571 Nov  6 11:59 fmo-os-rugged-tablet-7230.nix 
```
- If you wish to add a new hardware you may start from copying `hardware/example.nix` and modifying it
- If you wish to modify existing hardware you can start from modifying any of other HW descriptions
- HW description with `-public` suffix means that it can be built as open-source SW without any proprietary software included

# Hardware description file structure
Hardware description file is 100% valid nix file made to be as close to regular JSON file as possible to make it readable and modifyable to those who have never seen NIX before.

Typical hardware description file structure is following:
```nix
{
  # system and host description
  sysconf = {
    name = "example";
    description = "example OS with 2 VMs";
    systemPackages = [
      "vim"
      "tcpdump"
    ]; # systemPackages

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
```
System description starts from:
```nix
{
  sysconf = {
  };
}
```
`sysconf` is dictionary which describes whole system configuration. Also all root fields in `sysconf` mainly describe system HOST configuration, except `vms` field which describes virtual machines configurations.

For examlple to add system packages to HOST you may use following configuration:
```nix
{
  # system and host description
  sysconf = {
...
    systemPackages = [
      "your_super_package_to_add"
      "tcpdump"
    ]; # systemPackages
  };
}
```

If you wish to modify or add some default nix services or even add yours own service to HOST you need to use root's `extraModules` list:
```nix
extraModules = [];
```

`vms` field contains Virtual Machines configurations dictionary. Every field in this dict describes dedicated Virtual Machine and follow the same rules as HOST description.


# How to add a new virtual machine for existing HW
- Open Hardware Description file you want to modify
- Find `vms` section
- Add a new VM to `vms` section:
```nix
{
  sysconf = {
    ...
    vms = {
      ....
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
    ...
    }; # vms
  }; # sysconf
}
```
- `name`, `ipaddr`, `macaddr` - mandatory and should be uniq
- `extraModules` can be used to add additional services to VM


# Ghaf documentation links

The Ghaf Framework documentation site is located at [link](https://tiiuae.github.io/ghaf/)

# Release notes
v1.1.0a
* oras: /fmo/pmc-installer:v1.1.0a
```
- Registration Agent version: v0.8.4
- Chromium replaced with Google-Chrome
- Port 4223 has been removed
- Ports 7422, 7423 has been added
- Installer now shows only nvme - partition for install
- Added screen recording tool, records are stored at /home/ghaf/recordings/<datetime>.mp4
- Added fmo-tool: system management tool, documentation link: https://github.com/tiiuae/fmo-tool/blob/main/README.md
- Added Dynamic PortForwarding (DPF) feature: now you can open/close ports using fmo-tool
- Added Dynamic Device Passthrough (DDP) feature: now you can passthrough USB devices (like GPS, flash, Ybikey) using fmo-tool
- No need to insert password or delete .ssh/knownhosts, now you may ssh to VMs using fmo-tool
- Added ability to control Docker Compose Infrastructure (DCI) with fmo-tool
- VMs could be controlled with fmo-tool as well, started, stopped, restarted
- Also fmo-tool can show you current image version, RA version, IP configuration
- Image compression features were added, but not used for that release, yet
```
v1.0.2pre-RA_v1.0.0rc_enc_en
* oras: /fmo/pmc-installer:v1.0.2pre-RA_v1.0.0rc_enc_en
```
- Registration Agent version: v1.0.0rc encryption enabled
- FIX: installation fails if internet connection exist during the installation phase
- add portforwarding rules for NTP port 123 UDP and TCP
```
v1.0.2pre-RA_v1.0.0rc_enc_dis
* oras: /fmo/pmc-installer:v1.0.2pre-RA_v1.0.0rc_enc_dis
```
- Registration Agent version: v1.0.0rc encryption disabled
- FIX: installation fails if internet connection exist during the installation phase
- add portforwarding rules for NTP port 123 UDP and TCP
```
v1.0.2pre
* oras: /fmo/pmc-installer:v1.0.2pre
```
- Registration Agent version: v0.8.4
- FIX: installation fails if internet connection exist during the installation phase
- add portforwarding rules for NTP port 123 UDP and TCP
```
v1.0.1test
```
- Fix issue with registration agent path during installation
```
v1.0.1
```
- Registration Agent version: v0.8.4
- Fixed the HOST route issue, now host can access the internet also
- docker-compose file update mechanism has been introduced: right before the fmo-dci service start it checks if docker-compose.yml.new presents on file system and if it is, service will update docker-compose.yml file and store old one as .backup file
- container repository (ghcr.io or cr.airoplatform.com) now can be chosen during the installation
- also you can modify /var/lib/fogdata/cr.url file to change it
```
v1.0.0b
```
- Registration Agent version: v0.8.4
- terminal has been changed, added copy/paste options
- fixed issue with NAT connection for dockervm apps through netvm external IP address
- added UDP port forwarding rules for 4222, 7222, 4223 ports
- images uploaded to JFrog and cr.airoplatform.com
```
v1.0.0a
```
- Registration Agent version: v0.8.4
- fully dedicated FMO-OS git repository code base
- registration agent 0.8.4
- installer: added keyboard layout choose (FI, US)
- installer: added provisioning network choose (wlan, eth)
- GUI changed to SWAY with support for multi-monitor, multi-touch screens ( need manually modify config in /home/ghaf/.config/swayconfig )
- Added on screen keyboard
- Added layout change (FI, US)
- Added buttons to move apps between workspaces and app close button
- Added touchscreen gestures (two fingers swipe up: show onscreen keyboard, down: close onscreen keyboard, left/right: move to prev/next workspace)
- Added shutdown menu: lock, logout, reboot, shutdown
- Network connection management through NetworkManager GUI
- dockerCR URL changed to cr.airoplatform.com
- images uploaded to JFrog and cr.airoplatform.com
```
