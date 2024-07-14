{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  rocm-cmake,
  clr,
  gfortran,
  # rocblas,
  # rocsolver,
  hipblas,
  rocmUpdateScript,
  msgpack,
  python3,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "hipblaslt";
  version = "6.0.2";

  src = fetchFromGitHub {
    owner = "ROCm";
    repo = "hipBLASLt";
    rev = "rocm-${finalAttrs.version}";
    hash = "sha256-ZXiq5e6C7MU0nTpill/jCsjt1y3vwdt2xrrqCA6cCtw=";
  };

  nativeBuildInputs = [
    cmake
    rocm-cmake
    clr
    # gfortran
    (python3.withPackages (p: [
      p.joblib
      p.pyyaml
      p.msgpack
    ]))
  ];

  buildInputs = [
    msgpack
    hipblas
  ];

  meta = with lib; {
    description = "HipBLASLt is a library that provides general matrix-matrix operations with a flexible API and extends functionalities beyond a traditional BLAS library";
    homepage = "https://github.com/ROCm/hipBLASLt";
    changelog = "https://github.com/ROCm/hipBLASLt/blob/${src.rev}/CHANGELOG.md";
    license = licenses.mit;
    maintainers = teams.rocm.members;
    mainProgram = "hipblaslt";
    broken =
      versions.minor finalAttrs.version != versions.minor stdenv.cc.version
      || versionAtLeast finalAttrs.version "7.0.0";
    platforms = platforms.all;
  };
})
