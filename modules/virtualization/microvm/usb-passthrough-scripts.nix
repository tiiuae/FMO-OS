{pkgs}:
let
  getDeviceNode = pkgs.writeShellScriptBin "getDeviceNode" ''
            # Extract vendor ID and product ID
            v=''${1%:*}; p=''${1#*:}
            v=''${v#''${v%%[!0]*}}; p=''${p#''${p%%[!0]*}}
            ${pkgs.systemd}/bin/udevadm info --export-db |
            ${pkgs.gawk}/bin/awk -v p="PRODUCT=$v/$p" ' /DEVNAME=\/dev\/bus/ { a=1; gsub(/^[^=]*DEVNAME=/, "", $0); devname=$0; next; }  $0 ~ p && a==1 { a=0; print devname;  }'
        '';
in
{
  changeDeviceGroup = pkgs.writeShellScriptBin "changeDeviceGroup" ''
            # Get all devices listed in input file (format: "vendorID:productID")
            deviceList=$(${pkgs.coreutils}/bin/cat $1)

            # Exit in case no device found
            [[ -z "$deviceList" ]] && exit 0

            # Read and process each device
            while IFS= read -r device; do
                # Extract vendor ID and product ID
                v=''${device%:*}; p=''${device#*:}

                # Get device node
                deviceNode=$(${getDeviceNode}/bin/getDeviceNode $device)

                # Exit in case no device node found
		        [[ -z $deviceNode ]] && continue

                # Read device group
                deviceGroup=$(${pkgs.coreutils}/bin/stat -c "%G" "$deviceNode")

                # If the device group is not as desired, change it
                if [[ "$deviceGroup" != "kvm" ]]; then
                    ${pkgs.coreutils}/bin/chgrp kvm $deviceNode
                fi
            done <<< "$deviceList"

            # Reload udevadm
            ${pkgs.systemd}/bin/udevadm control --reload-rules && ${pkgs.systemd}/bin/udevadm trigger
        '';

  generateQemuUSBOptions = pkgs.writeShellScriptBin "generateQemuUSBOptions" ''
            # Get all devices listed in input file (format: "vendorID:productID")
            deviceList=$(${pkgs.coreutils}/bin/cat $1)

            # Exit in case no device found
            [[ -z "$deviceList" ]] && exit 0

            # Read and process each device
            while IFS= read -r device; do
                # Extract vendor ID and product ID
                v=''${device%:*}; p=''${device#*:}

                # Generate qemu command options
                echo -n " -usb -device usb-host,vendorid=0x$v,productid=0x$p"
            done <<< "$deviceList"
        '';
}
