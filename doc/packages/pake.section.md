# Pake {#sec-pake}

[Pake](https://github.com/tw93/pake) turns any webpage into a lightweight
desktop application built with Rust and Tauri.

## The `pake` CLI {#sec-pake-cli}

The `pake` package provides the `pake` command, which compiles a Tauri app for a
given URL at runtime:

```ShellSession
$ pake https://example.com --name Example --no-bundle
```

Because the Rust/Tauri app is compiled on demand, the first invocation downloads
the required crates and takes several minutes. Pake writes into a per-version,
writable copy of its project tree under `$XDG_CACHE_HOME/pake`.

On Nixpkgs the deb/AppImage bundlers cannot run (they probe the host for an
appindicator library and `linuxdeploy`), so the CLI defaults to `--no-bundle`
and emits a raw, natively runnable executable instead of an installer.

## Building a webpage into a package with `pake.mkApp` {#sec-pake-mkapp}

`pake.mkApp` builds a single webpage into a self-contained desktop application
at **build time**, producing a wrapped executable, a `.desktop` entry and an
icon. Unlike the `pake` CLI it needs no network or Rust toolchain at runtime, so
the result can be added directly to `environment.systemPackages` or a profile.

It accepts either a URL string or an attribute set:

```nix
{ pkgs, ... }:
{
  environment.systemPackages = [
    # Shorthand: the application name is derived from the URL host.
    (pkgs.pake.mkApp "https://example.com")

    # With options.
    (pkgs.pake.mkApp {
      url = "https://account.proton.me/mail";
      name = "ProtonMail";
      icon = ./protonmail.png; # optional
      extraFlags = [ "--width" "1200" "--height" "800" ]; # optional, passed to pake
    })
  ];
}
```

The resulting package is named `pake-<name>` and its executable is
`pake-<name>`.

Supported arguments:

- `url` (required): the webpage to package.
- `name`: the human-readable application name. Defaults to the URL host.
- `icon`: a path to a PNG/ICNS icon. Because the sandbox has no network, the
  site's favicon cannot be fetched automatically; when omitted, Pake's generic
  icon is used. Pass your own icon (for example a `fetchurl`ed favicon) for a
  site-specific look.
- `extraFlags`: extra command-line flags forwarded to `pake`.

::: {.note}
`pake.mkApp` is Linux-only, as it relies on the GTK/WebKit stack.
:::

::: {.note}
WebAuthn / security keys (including passkeys) do not work in `pake.mkApp`
applications: the WebKitGTK build in Nixpkgs is compiled without WebAuthn
support (`ENABLE_WEB_AUTHN` is off and the GTK port ships no authenticator
backend). Sites that require a security key for login cannot be used; choose a
different second factor (such as a TOTP app) where possible.
:::
