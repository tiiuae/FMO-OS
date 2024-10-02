# Copyright 2022-2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{
  python3Packages,
  fetchFromGitLab,
  lib,
}:
python3Packages.buildPythonPackage rec {
  pname = "qemu.qmp";
  version = "0.0.3";
  format = "pyproject";

  src = fetchFromGitLab {
    owner = "qemu-project";
    repo = "python-qemu-qmp";
    rev = "v${version}";
    hash = "sha256-NOtBea81hv+swJyx8Mv2MIqoK4/K5vyMiN12hhDEpJY=";
  };

  SETUPTOOLS_SCM_PRETEND_VERSION = version;

  nativeBuildInputs = with python3Packages;[
    setuptools
    setuptools-scm
    wheel
  ];

  pythonImportsCheck = [ "qemu.qmp" ];

  meta = {
    homepage = "https://www.qemu.org/";
    description = "QEMU Monitor Protocol library";
  };
}
