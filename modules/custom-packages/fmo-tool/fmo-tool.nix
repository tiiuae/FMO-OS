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
    rev = "40ca851d4f51af7ecf48939394609c6520b5d549";
    ref = "refs/heads/integrate_ddp";
  };
}