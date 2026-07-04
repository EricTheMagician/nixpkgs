#!@shell@
# Pake compiles a fresh Tauri app on every run, writing into its own project
# tree (src-tauri/target, src-tauri/.cargo, src-tauri/.pake/tauri.conf.json).
# The Nix store is read-only, so materialize a per-version, writable copy under
# the user's cache directory and run pake from there.
set -eu

export PATH="@binPath@${PATH:+:$PATH}"
export PKG_CONFIG_PATH="@pkgConfigPath@${PKG_CONFIG_PATH:+:$PKG_CONFIG_PATH}"

state="${XDG_CACHE_HOME:-$HOME/.cache}/pake/@version@"
if [ ! -e "$state/.ready" ]; then
  rm -rf "$state"
  mkdir -p "$state"
  # dist/cli.js must be a real file: Node realpaths ESM module paths and pake
  # derives its project directory from the module location. node_modules can
  # stay a symlink into the (read-only) store; src-tauri must be writable.
  cp -r --no-preserve=mode @out@/lib/pake/dist "$state/dist"
  cp --no-preserve=mode @out@/lib/pake/package.json "$state/package.json"
  cp -r --no-preserve=mode @out@/lib/pake/src-tauri "$state/src-tauri"
  ln -s @out@/lib/pake/node_modules "$state/node_modules"
  touch "$state/.ready"
fi

exec @node@ "$state/dist/cli.js" "$@"
