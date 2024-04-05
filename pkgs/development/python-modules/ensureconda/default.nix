{
  lib,
  buildPythonPackage,
  fetchPypi,
  # build dependencies
  hatchling,
  hatch-vcs,
  # run time dependencies
  appdirs,
  click,
  filelock,
  requests,
}:
buildPythonPackage rec {
  pname = "ensureconda";
  version = "1.4.4";
  format = "pyproject";

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-LucLdfaqZ/yltyvsUU5m3rAWeSlZdjy9SHIM/gUaJKQ=";
  };

  build-system = [
    hatchling
    hatch-vcs
  ];
  dependencies = [
    appdirs
    click
    filelock
    requests
  ];

  meta = {
    description = "Simple installer for conda (and conda-likes)";
    homepage = "https://github.com/conda-incubator/ensureconda";
    license = lib.licenses.mit;
  };
}
