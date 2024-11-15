# Derived from https://github.com/NixOS/nixpkgs/blob/nixos-24.05/pkgs/by-name/pk/pkcs11-provider/package.nix
{
  lib,
  pkgs,
  ...
}:

pkgs.stdenv.mkDerivation rec {
  pname = "pkcs11-provider";
  version = "0.5";

  src = pkgs.fetchFromGitHub {
    owner = "latchset";
    repo = "pkcs11-provider";
    rev = "v${version}";
    hash = "sha256-ii2xQPBgqIjrAP27qTQR9IXbEGZcc79M/cYzFwcAajQ=";
  };

  buildInputs = with pkgs; [ openssl nss p11-kit ];
  nativeBuildInputs = with pkgs; [ meson ninja pkg-config ];
  nativeCheckInputs = with pkgs; [ p11-kit.bin opensc nss.tools gnutls openssl.bin expect ];

  postPatch = ''
    patchShebangs --build .
  '';

  preInstall = ''
    # Meson tries to install to `$out/$out` and `$out/''${openssl.out}`; so join them.
    mkdir -p "$out"
    for dir in "$out" "${pkgs.openssl.out}"; do
      mkdir -p .install/"$(dirname -- "$dir")"
      ln -s "$out" ".install/$dir"
    done
    export DESTDIR="$(realpath .install)"
  '';

  enableParallelBuilding = true;
  enableParallelInstalling = false;
  doCheck = true;

  passthru.updateScript = pkgs.nix-update-script {
    extraArgs = [ "--version-regex" "v(\d\.\d)"];
  };

  meta = with lib; {
    homepage = "https://github.com/latchset/pkcs11-provider";
    description = "An OpenSSL 3.x provider to access hardware or software tokens using the PKCS#11 Cryptographic Token Interface";
    maintainers = with maintainers; [ numinit ];
    license = licenses.asl20;
    platforms = platforms.unix;
  };
}
