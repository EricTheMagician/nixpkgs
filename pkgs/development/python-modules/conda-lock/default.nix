{
  lib,
  buildPythonPackage,
  pythonAtLeast,
  fetchPypi,
  # build-dependencies
  hatchling,
  hatch-vcs,
  pythonRelaxDepsHook,
  # runtime dependencies
  cachy,
  cachecontrol,
  click-default-group,
  click,
  clikit,
  conda,
  crashtest,
  ensureconda,
  gitpython,
  requests,
  html5lib,
  jinja2,
  keyring,
  pkginfo,
  pydantic,
  pyyaml,
  tomlkit,
  toolz,
  urllib3,
  virtualenv,
}:
buildPythonPackage rec {
  pname = "conda_lock";
  version = "2.5.6";
  format = "pyproject";

  src = fetchPypi {
    inherit pname version;
    sha256 = "sha256-Mj24tkOLRmSMS6TauBVHhR7oJm2+kTaA94N8lMxfECM=";
  };

  build-system = [
    pythonRelaxDepsHook
    hatchling
    hatch-vcs
  ];
  dependencies = [
    cachy
    cachecontrol
    click-default-group
    click
    clikit
    conda
    crashtest
    ensureconda
    gitpython
    html5lib
    jinja2
    keyring
    pkginfo
    pydantic
    pyyaml
    requests
    tomlkit
    toolz
    urllib3
    virtualenv
  ];

  pythonRelaxDeps = [ "urllib3" ];

  # No tests
  # doCheck = false;

  meta = {
    description = "Lightweight lockfile for conda environments";
    homepage = "https://github.com/conda/conda-lock";
    license = lib.licenses.mit;
  };
}
