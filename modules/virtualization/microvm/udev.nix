# Perform substitutions in all udev rules files.
{ name, udevPackages, udevPath, udev, systemd, binPackages, pkgs, lib, config, initrdBin ? null }: pkgs.runCommand name
    { preferLocalBuild = true;
      allowSubstitutes = false;
      packages = lib.unique (map toString udevPackages);
    }
    ''
      mkdir -p $out
      shopt -s nullglob
      set +o pipefail

      # Set a reasonable $PATH for programs called by udev rules.
      echo 'ENV{PATH}="${udevPath}/bin:${udevPath}/sbin"' > $out/00-path.rules

      # Add the udev rules from other packages.
      for i in $packages; do
        echo "Adding rules for package $i"
        for j in $i/{etc,lib}/udev/rules.d/*; do
          echo "Copying $j to $out/$(basename $j)"
          cat $j > $out/$(basename $j)
        done
      done

      # Fix some paths in the standard udev rules.  Hacky.
      for i in $out/*.rules; do
        substituteInPlace $i \
          --replace \"/sbin/modprobe \"${pkgs.kmod}/bin/modprobe \
          --replace \"/sbin/mdadm \"${pkgs.mdadm}/sbin/mdadm \
          --replace \"/sbin/blkid \"${pkgs.util-linux}/sbin/blkid \
          --replace \"/bin/mount \"${pkgs.util-linux}/bin/mount \
          --replace /usr/bin/readlink ${pkgs.coreutils}/bin/readlink \
          --replace /usr/bin/basename ${pkgs.coreutils}/bin/basename 2>/dev/null
      ${lib.optionalString (initrdBin != null) ''
        substituteInPlace $i --replace '/run/current-system/systemd' "${lib.removeSuffix "/bin" initrdBin}"
      ''}
      done

      echo -n "Checking that all programs called by relative paths in udev rules exist in ${udev}/lib/udev... "
      import_progs=$(grep 'IMPORT{program}="[^/$]' $out/* |
        sed -e 's/.*IMPORT{program}="\([^ "]*\)[ "].*/\1/' | uniq)
      run_progs=$(grep -v '^[[:space:]]*#' $out/* | grep 'RUN+="[^/$]' |
        sed -e 's/.*RUN+="\([^ "]*\)[ "].*/\1/' | uniq)
      for i in $import_progs $run_progs; do
        if [[ ! -x ${udev}/lib/udev/$i && ! $i =~ socket:.* ]]; then
          echo "FAIL"
          echo "$i is called in udev rules but not installed by udev"
          exit 1
        fi
      done
      echo "OK"

      echo -n "Checking that all programs called by absolute paths in udev rules exist... "
      import_progs=$(grep 'IMPORT{program}="\/' $out/* |
        sed -e 's/.*IMPORT{program}="\([^ "]*\)[ "].*/\1/' | uniq)
      run_progs=$(grep -v '^[[:space:]]*#' $out/* | grep 'RUN+="/' |
        sed -e 's/.*RUN+="\([^ "]*\)[ "].*/\1/' | uniq)
      for i in $import_progs $run_progs; do
        # if the path refers to /run/current-system/systemd, replace with config.systemd.package
        if [[ $i == /run/current-system/systemd* ]]; then
          i="${systemd}/''${i#/run/current-system/systemd/}"
        fi

        if [[ ! -x $i ]]; then
          echo "FAIL"
          echo "$i is called in udev rules but is not executable or does not exist"
          exit 1
        fi
      done
      echo "OK"

      filesToFixup="$(for i in "$out"/*; do
        # list all files referring to (/usr)/bin paths, but allow references to /bin/sh.
        grep -P -l '\B(?!\/bin\/sh\b)(\/usr)?\/bin(?:\/.*)?' "$i" || :
      done)"

      if [ -n "$filesToFixup" ]; then
        echo "Consider fixing the following udev rules:"
        echo "$filesToFixup" | while read localFile; do
          remoteFile="origin unknown"
          for i in ${toString binPackages}; do
            for j in "$i"/*/udev/rules.d/*; do
              [ -e "$out/$(basename "$j")" ] || continue
              [ "$(basename "$j")" = "$(basename "$localFile")" ] || continue
              remoteFile="originally from $j"
              break 2
            done
          done
          refs="$(
            grep -o '\B\(/usr\)\?/s\?bin/[^ "]\+' "$localFile" \
              | sed -e ':r;N;''${s/\n/ and /;br};s/\n/, /g;br'
          )"
          echo "$localFile ($remoteFile) contains references to $refs."
        done
        exit 1
      fi

      # If auto-configuration is disabled, then remove
      # udev's 80-drivers.rules file, which contains rules for
      # automatically calling modprobe.
      ${lib.optionalString (!config.boot.hardwareScan) ''
        ln -s /dev/null $out/80-drivers.rules
      ''}
    ''