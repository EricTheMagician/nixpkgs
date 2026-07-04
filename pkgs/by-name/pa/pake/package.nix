{
  lib,
  stdenv,
  fetchFromGitHub,
  nix-update-script,

  nodejs,
  pnpm_10,
  pnpmConfigHook,
  fetchPnpmDeps,

  # Runtime dependencies: `pake <url>` compiles a Tauri app on the fly, so it
  # needs a Rust toolchain and the GTK/WebKit stack on PATH / PKG_CONFIG_PATH.
  cargo,
  rustc,
  pkg-config,
  glib,
  gtk3,
  webkitgtk_4_1,
  libsoup_3,

  # Used by passthru.mkApp to build a specific webpage into a desktop app.
  rustPlatform,
  wrapGAppsHook3,
  makeDesktopItem,
  copyDesktopItems,
  gsettings-desktop-schemas,
  librsvg,
  gdk-pixbuf,
  libayatana-appindicator,
  glib-networking,
  gst_all_1,
}:
let
  pnpm = pnpm_10;
in
stdenv.mkDerivation (finalAttrs: {
  pname = "pake";
  version = "3.13.1";

  src = fetchFromGitHub {
    owner = "tw93";
    repo = "pake";
    tag = "V${finalAttrs.version}";
    hash = "sha256-Wmkt95aorIw4OXWK6ZhkqEBRx+nM/w5zb3srcl882wI=";
  };

  pnpmDeps = fetchPnpmDeps {
    inherit (finalAttrs) pname version src;
    inherit pnpm;
    fetcherVersion = 3;
    hash = "sha256-YZZTzZQe2U/Uxu90yWHdamfKPByl8kl72/gata0LQpA=";
  };

  nativeBuildInputs = [
    nodejs
    pnpm
    pnpmConfigHook
    pkg-config
  ];

  # Not needed to build pake itself, but listing the GTK/WebKit stack here lets
  # the pkg-config setup hook assemble the full transitive pkg-config search
  # path, which is baked into the launcher so `pake <url>` can compile the
  # generated Tauri app at runtime.
  buildInputs = [
    glib
    gtk3
    webkitgtk_4_1
    libsoup_3
  ];

  postPatch = ''
    # Pake ships with a complete node_modules from Nix, so the redundant runtime
    # `pnpm install` / `npm install` (which would need network and a writable
    # store) is neutralised at its call site - the deps are already present when
    # pake builds. getInstallCommand itself is left intact so its unit tests pass.
    substituteInPlace bin/builders/BaseBuilder.ts \
      --replace-fail \
        'getInstallCommand(packageManager, useCnMirror)' \
        "'true'"

    # The Tauri deb/AppImage bundlers cannot work under Nix (they scan the host
    # for an appindicator library / linuxdeploy). Default to --no-bundle so
    # `pake <url>` yields a raw executable that runs natively against the store.
    substituteInPlace bin/defaults.ts \
      --replace-fail 'bundle: true,' 'bundle: false,'
  '';

  buildPhase = ''
    runHook preBuild

    # Bundle bin/cli.ts -> dist/cli.js
    pnpm run cli:build

    runHook postBuild
  '';

  # Run pake's own test suite (Vitest unit + integration tests).
  doCheck = true;
  checkPhase = ''
    runHook preCheck

    node_modules/.bin/vitest run

    runHook postCheck
  '';

  installPhase = ''
    runHook preInstall

    # Drop dev-only dependencies now that the bundle and tests are done.
    pnpm prune --prod --ignore-scripts
    # https://github.com/pnpm/pnpm/issues/3645
    find node_modules -xtype l -delete
    rm -f node_modules/.modules.yaml

    mkdir -p $out/lib/pake
    cp -r dist src-tauri node_modules package.json $out/lib/pake/

    # `pake <url>` needs a Rust toolchain plus the GTK/WebKit stack to compile
    # the Tauri app, and a writable copy of its project tree (see launcher).
    # The pkg-config setup hook exposes the full transitive search path via
    # PKG_CONFIG_PATH_FOR_TARGET; bake it in so the -sys crates resolve at runtime.
    mkdir -p $out/bin
    substitute ${./pake-launcher.sh} $out/bin/pake \
      --subst-var-by shell ${stdenv.shell} \
      --subst-var-by node ${lib.getExe nodejs} \
      --subst-var out \
      --subst-var-by version "${finalAttrs.version}" \
      --subst-var-by binPath ${
        lib.makeBinPath [
          nodejs
          pnpm
          cargo
          rustc
          pkg-config
          stdenv.cc
        ]
      } \
      --subst-var-by pkgConfigPath "''${PKG_CONFIG_PATH_FOR_TARGET:-$PKG_CONFIG_PATH}"
    chmod +x $out/bin/pake

    runHook postInstall
  '';

  passthru = {
    updateScript = nix-update-script {
      extraArgs = [
        "--version-regex"
        "V(.*)"
        # Also refresh the vendored Cargo hash used by passthru.mkApp.
        "--subpackage"
        "cargoDeps"
      ];
    };

    # Cargo dependencies of pake's bundled Tauri project (src-tauri), vendored
    # so mkApp can compile a webpage into a desktop app offline in the sandbox.
    cargoDeps = rustPlatform.fetchCargoVendor {
      src = "${finalAttrs.src}/src-tauri";
      hash = "sha256-dEj0Zo5ioLETtOQolU1fV/RBbMrlhxJgodXt69DTVUE=";
    };

    # Build a single webpage into a native, installable desktop app.
    #
    # Usage in configuration.nix:
    #   environment.systemPackages = [
    #     (pkgs.pake.mkApp "https://account.proton.me/mail")
    #     (pkgs.pake.mkApp {
    #       url = "https://account.proton.me/mail";
    #       name = "ProtonMail";
    #       icon = ./protonmail.png; # optional; defaults to pake's generic icon
    #     })
    #   ];
    #
    # Unlike `pake <url>` (which compiles at runtime), this compiles the Tauri
    # app at build time so the result is a self-contained package with a
    # .desktop entry and icon, ready for systemPackages.
    mkApp =
      argsOrUrl:
      let
        args = if builtins.isString argsOrUrl then { url = argsOrUrl; } else argsOrUrl;
        url = args.url;
        name =
          args.name or (
            let
              afterProto = lib.last (lib.splitString "//" url);
            in
            lib.head (lib.splitString "/" afterProto)
          );
        slug = lib.toLower (builtins.replaceStrings [ " " "." "/" ":" "_" ] [ "-" "-" "-" "-" "-" ] name);
        pname = "pake-${slug}";
        icon = args.icon or "${finalAttrs.finalPackage}/lib/pake/src-tauri/icons/icon.png";
        extraFlags = args.extraFlags or [ ];

        # WebKitGTK plays media through GStreamer, which it dlopen()s at runtime
        # from GST_PLUGIN_SYSTEM_PATH_1_0. Without these plugins the app reports
        # errors such as "GStreamer element appsink not found" and audio/video
        # (including WebRTC calls) fail.
        gstPlugins = [
          gst_all_1.gstreamer
          gst_all_1.gst-plugins-base
          gst_all_1.gst-plugins-good
          gst_all_1.gst-plugins-bad
          gst_all_1.gst-libav
        ];
      in
      stdenv.mkDerivation {
        inherit pname;
        inherit (finalAttrs) version;

        inherit (finalAttrs.passthru) cargoDeps;
        cargoRoot = "src-tauri";

        nativeBuildInputs = [
          nodejs
          pnpm
          cargo
          rustc
          pkg-config
          rustPlatform.cargoSetupHook
          copyDesktopItems
          wrapGAppsHook3
        ];

        buildInputs = [
          glib
          gtk3
          webkitgtk_4_1
          libsoup_3
          gsettings-desktop-schemas
          librsvg
          gdk-pixbuf
          libayatana-appindicator
          # WebKitGTK needs glib-networking's GIO module for TLS/HTTPS;
          # wrapGAppsHook3 exposes it via GIO_EXTRA_MODULES.
          glib-networking
        ]
        ++ gstPlugins;

        # Two runtime search paths wrapGAppsHook3 doesn't set on its own:
        #  - pake's system tray dlopen()s the appindicator library, so it needs
        #    to be on LD_LIBRARY_PATH rather than just linked.
        #  - WebKitGTK dlopen()s GStreamer plugins from GST_PLUGIN_SYSTEM_PATH_1_0.
        # Append to the bash array wrapGAppsHook3 uses to build the wrapper.
        preFixup = ''
          gappsWrapperArgs+=(
            --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [ libayatana-appindicator ]}
            --prefix GST_PLUGIN_SYSTEM_PATH_1_0 : "${
              lib.makeSearchPathOutput "lib" "lib/gstreamer-1.0" gstPlugins
            }"
          )
        '';

        # Reuse the already-built pake project tree (dist + node_modules +
        # src-tauri). cargoSetupHook then vendors src-tauri's crates.
        unpackPhase = ''
          runHook preUnpack

          cp -r ${finalAttrs.finalPackage}/lib/pake ./source
          chmod -R u+w ./source
          sourceRoot=source

          runHook postUnpack
        '';

        buildPhase = ''
          runHook preBuild

          export HOME="$TMPDIR"
          export CI=true
          export NO_UPDATE_NOTIFIER=1
          export CARGO_NET_OFFLINE=true

          node dist/cli.js ${lib.escapeShellArg url} \
            --name ${lib.escapeShellArg name} \
            --icon ${lib.escapeShellArg icon} \
            --no-bundle \
            ${lib.escapeShellArgs extraFlags}

          runHook postBuild
        '';

        installPhase = ''
          runHook preInstall

          binary=$(find . -maxdepth 1 -name '*-binary' | head -n1)
          if [ -z "$binary" ]; then
            echo "pake: no raw binary produced by --no-bundle build" >&2
            exit 1
          fi
          install -Dm755 "$binary" "$out/bin/${pname}"

          install -Dm644 ${lib.escapeShellArg icon} \
            "$out/share/icons/hicolor/512x512/apps/${pname}.png"

          runHook postInstall
        '';

        desktopItems = [
          (makeDesktopItem {
            name = pname;
            exec = pname;
            icon = pname;
            desktopName = name;
            comment = "${name} (Pake)";
            categories = [
              "Network"
              "WebBrowser"
            ];
          })
        ];

        meta = finalAttrs.meta // {
          description = "${name} as a desktop app, built with Pake";
          mainProgram = pname;
        };
      };
  };

  meta = {
    description = "Turn any webpage into a desktop app with one command, built with Rust and Tauri";
    homepage = "https://github.com/tw93/pake";
    changelog = "https://github.com/tw93/pake/releases/tag/V${finalAttrs.version}";
    license = lib.licenses.gpl3Plus;
    maintainers = with lib.maintainers; [ ericthemagician ];
    mainProgram = "pake";
    platforms = lib.platforms.linux;
  };
})
