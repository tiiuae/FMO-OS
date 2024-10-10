{ stdenv, lib, qt5, saneBackends, makeWrapper, fetchurl }:
stdenv.mkDerivation rec {
  name = "google-chrome";
  version = "current";

  src = fetchurl {
    url = "https://dl.google.com/linux/direct/google-chrome-stable_${version}_amd64.deb";
    hash = "sha256-1z26qjhbiyz33rm7mp8ycgl5ka0v3v5lv5i5v0b5mx35arvx2zzy";
  };
  sourceRoot = ".";
  unpackCmd = "dpkg-deb -x google-chrome-stable_${version}_amd64.deb .";

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    cp -R usr/share opt $out/
    # fix the path in the desktop file
    substituteInPlace \
      $out/share/applications/google-chrome.desktop \
      --replace /opt/ $out/opt/
    # symlink the binary to bin/
    ln -s $out/opt/google/chrome/chrome $out/bin/google-chrome

    runHook postInstall
  '';
  preFixup = let
    # we prepare our library path in the let clause to avoid it become part of the input of mkDerivation
    libPath = lib.makeLibraryPath [
      qt5.qtbase        # libQt5PrintSupport.so.5
      qt5.qtsvg         # libQt5Svg.so.5
      stdenv.cc.cc.lib  # libstdc++.so.6
      saneBackends      # libsane.so.1
    ];
  in ''
    patchelf \
      --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" \
      --set-rpath "${libPath}" \
      $out/opt/google/chrome/chrome
  '';

  meta = with lib; {
    homepage = https://google.com/;
    description = "google-chrome WEB-browser";
    license = licenses.unfree;
    platforms = platforms.linux;
    maintainers = [ your_name ];
  };
}
