# FMO-OS
* Operating System for Flight and Mission Operations devices
* A ghaf-based operating system designed specifically for FMO devices
* Currently support: Dell Latitude 7230 Rugged Extreme Tablet & Dell Latitude 7330 Rugged Extreme Laptop
## Release note
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
