{
  lib,
  stdenv,
  fetchFromGitHub,
  gradle,
  jdk,
  stripJavaArchivesHook,
  neo4j,
  nix-update,
  writeShellScript,
}:

stdenv.mkDerivation (finalAttrs: rec {
  pname = "neo4j-apoc";
  version = "2025.11.0";

  src = fetchFromGitHub {
    owner = "neo4j";
    repo = "apoc";
    rev = version;
    hash = "sha256-Y9hr+EKRZk8Pq7m4uI3siXfOhsH9fPEtG/HCxqBcYVE=";
  };
  nativeBuildInputs = [
    gradle
    jdk
    stripJavaArchivesHook
    neo4j
  ];
  postPatch = ''
    sed -i '/com.neo4j:enterprise-it-test-support/d' core/build.gradle

    # Force version
    sed -i '/^version=/d' gradle.properties
    echo "" >> gradle.properties
    echo "version=${finalAttrs.version}" >> gradle.properties
  '';

  mitmCache = gradle.fetchDeps {
    pkg = finalAttrs.finalPackage;
    data = ./deps.json;
  };

  __darwinAllowLocalNetworking = true;

  gradleFlags = [
    "-Pneo4jVersionOverride=${finalAttrs.version}"
  ];

  gradleBuildTask = "shadowJar";
  doCheck = false;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/neo4j/plugins
    cp core/build/libs/apoc-*-core.jar $out/share/neo4j/plugins/apoc.jar
    runHook postInstall
  '';

  passthru.updateScript = writeShellScript "update-neo4j-apoc" ''
    ${lib.getExe nix-update} neo4j-apoc
    $(nix-build -A neo4j-apoc.mitmCache.updateScript)
  '';

  meta = {
    description = "";
    homepage = "https://github.com/neo4j/apoc";
    license = lib.licenses.asl20;
    maintainers = with lib.maintainers; [ ];
    mainProgram = "neo4j-apoc";
    platforms = lib.platforms.all;
  };
})
