{ pkgs }:

pkgs.python310Packages.buildPythonApplication {
  pname = "fmo-tool";
  version = "0.0.1";

  build-system = with pkgs.python310Packages; [
    setuptools
    wheel
  ];

  dependencies = with pkgs.python310Packages; [
    typer
    colorama
    shellingham
    pytest
#    typing_extensions
    pyyaml
    paramiko
#    py3compat
    rich
  ];

  propagatedBuildInputs = with pkgs.python310Packages; [
    (pkgs.python310.withPackages (ps: with ps; [ pip ]))
    typer
    colorama
    shellingham
    pytest
 #   typing_extensions
    pyyaml
    paramiko
 #   py3compat
    rich
  ];

  src = builtins.fetchGit {
    url = "git@github.com:tiiuae/fmo-tool.git";
    rev = "e797aad27578316945daa0b133058c1e753119ac";
    ref = "refs/heads/main";
  };
}
