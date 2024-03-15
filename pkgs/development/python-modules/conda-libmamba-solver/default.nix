{
  lib,
  buildPythonPackage,
  pythonRelaxDepsHook,
  fetchFromGitHub,
  libmambapy,
  hatchling,
  hatch-vcs,
  boltons,
}:
buildPythonPackage rec {
  pname = "conda-libmamba-solver";
  version = "24.1.0";
  pyproject = true;

  src = fetchFromGitHub {
    inherit pname version;
    owner = "conda";
    repo = "conda-libmamba-solver";
    rev = version;
    hash = "sha256-vsUYrDVNMKHd3mlaAFYCP4uPQ9HxeKsose5O8InaMcE=";
  };

  build-system = [
    pythonRelaxDepsHook
    hatchling
    hatch-vcs
  ];

  dependencies = [
    boltons
    libmambapy
  ];
  pythonRemoveDeps = [ "conda" ];

  meta = {
    description = "The libmamba based solver for conda.";
    homepage = "https://github.com/conda/conda-libmamba-solver";
    license = lib.licenses.bsd3;
    maintainers = [ lib.maintainers.ericthemagician ];
  };
}
