{
  stdenv,
  lib,
  fetchFromGitHub,
  python3Packages,
  xkeyboard_config,
}:
python3Packages.buildPythonPackage rec {
  pname = "sway-input-config";
  version = "1.4.2";

  src = fetchFromGitHub {
    owner = "Sunderland93";
    repo = pname;
    rev = "v${version}";
    sha256 = "sha256-By03kzT3ypJY5R/B1YMwf1poxvW5cqJe72jiR4x5RL4=";
  };

  #format = "setuptools";

  # Non-Python deps for build and run-time
  buildInputs = [
    xkeyboard_config
  ];

  # Build-time only Python deps
  build-system = with python3Packages; [
    setuptools
  ];

  # Build and run-time Python deps
  dependencies = with python3Packages; [
    pyqt6
    i3ipc
  ];

  # No tests defined
  doCheck = false;
  doInstallCheck = false;

  patches = [./support-only-linux.patch];
  postPatch = ''
    substituteInPlace sway_input_config/main.py \
      --replace /usr ${xkeyboard_config}
  '';

  meta = with lib; {
    description = "Input device configurator for Sway ";
    homepage = "https://github.com/Sunderland93/sway-input-config";
    license = licenses.gpl3;
    platforms = platforms.linux;
  };
}
