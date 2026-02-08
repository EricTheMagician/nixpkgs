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

  # Build both frontend and backend
  buildPhase = ''
    runHook preBuild

    # Build frontend (React app) and backend
    npm run build

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
    cp -r public $out/share/termix/ 2>/dev/null || true
    cp package.json $out/share/termix/

    # Copy built frontend to html directory (Vite builds to dist)
    cp -r dist $out/share/termix/html/

    # Copy locales and fonts
    cp -r src/locales $out/share/termix/html/
    cp -r public/fonts $out/share/termix/html/

    # Copy nginx configuration from docker
    cp -r docker/nginx*.conf $out/share/termix/nginx/

    runHook postInstall
  '';

  # The main entry point
  postFixup = ''
    makeWrapper ${nodejs}/bin/node $out/bin/termix \
      --set NODE_ENV production \
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
