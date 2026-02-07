{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
  python3,
  openssl,
  nodejs,
  makeWrapper,
}:

buildNpmPackage (finalAttrs: {
  pname = "termix";
  version = "1.11.0";

  src = fetchFromGitHub {
    owner = "Termix-SSH";
    repo = "Termix";
    rev = "release-${finalAttrs.version}-tag";
    hash = "sha256-aGP5U1VUm9e+mxiclwd72OLQxrs90sw5HT5dC9fdfyA=";
  };

  npmDepsHash = "sha256-PrR01zV8PnT5x/oEa9eQjq/2d9TdQ7efYx9djVrBo8o=";

  makeCacheWritable = true;
  npmFlags = [ "--ignore-scripts" ];

  nativeBuildInputs = [
    python3
    openssl
  ];

  # Increase memory limit for build
  NODE_OPTIONS = "--max-old-space-size=3072";

  # Skip default build script - we'll run manual steps
  dontNpmBuild = true;

  # Manually build backend only
  buildPhase = ''
    runHook preBuild

    # Compile TypeScript for backend
    npx tsc -p tsconfig.node.json

    # Rebuild better-sqlite3 native bindings
    npm rebuild better-sqlite3

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    # Create directories
    mkdir -p $out/bin
    mkdir -p $out/share/termix
    mkdir -p $out/share/termix/data
    mkdir -p $out/share/termix/uploads
    mkdir -p $out/share/termix/html
    mkdir -p $out/share/termix/nginx

    # Copy built files and dependencies
    cp -r dist/backend $out/share/termix/
    cp -r dist $out/share/termix/
    cp -r node_modules $out/share/termix/
    cp -r html $out/share/termix/ 2>/dev/null || true
    cp -r public $out/share/termix/ 2>/dev/null || true
    cp package.json $out/share/termix/

    runHook postInstall
  '';

  # The main entry point
  postFixup = ''
    makeWrapper ${nodejs}/bin/node $out/bin/termix \
      --set NODE_ENV production \
      --set-default DATA_DIR $out/share/termix/data \
      --set-default PORT 8080 \
      --chdir $out/share/termix \
      --add-flags $out/share/termix/dist/backend/backend/starter.js
  '';

  meta = {
    description = "Termix is a web-based server management platform with SSH terminal, tunneling, and file editing capabilities";
    homepage = "https://github.com/Termix-SSH/Termix";
    license = lib.licenses.asl20;
    maintainers = with lib.maintainers; [ ericthemagician ];
    mainProgram = "termix";
    platforms = lib.platforms.all;
  };
})
