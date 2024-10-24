{ pkgs }:
let
  # WAR: This is because current typer and paramiko dependencies are old versions,
  # Solve by manually build newer versions of the packages
  # Will be remove in new version of nixpkgs (with pkgs.python3Packages)
  typer = pkgs.callPackage ./typer.nix {};
  paramiko = pkgs.callPackage ./paramiko.nix {};
in

pkgs.python3Packages.buildPythonApplication {
  pname = "fmo-tool";
  version = "0.0.1";

  build-system = with pkgs.python3Packages; [
    setuptools
    wheel
  ];

  dependencies = with pkgs.python3Packages; [
    typer
    colorama
    shellingham
    pytest
    typing-extensions
    pyyaml
    paramiko
#    py3compat
    rich
  ];

  propagatedBuildInputs = with pkgs.python3Packages; [
    (pkgs.python3.withPackages (ps: with ps; [ pip ]))
    typer
    colorama
    shellingham
    pytest
    typing-extensions
    pyyaml
    paramiko
 #   py3compat
    rich
  ];

  src = builtins.fetchGit {
    url = "git@github.com:tiiuae/fmo-tool.git";
    rev = "4cdb772a104893ecf2d15333bad0f335040c3be9";
    ref = "refs/heads/main";
  };
}
