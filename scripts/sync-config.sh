#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

sync_file() {
  local src="$1"
  local dest="$2"

  if [ -f "$src" ]; then
    mkdir -p "$(dirname "$dest")"
    cp "$src" "$dest"
    echo "synced: $src -> $dest"
  else
    echo "skip (missing): $src"
  fi
}

sync_file "$HOME/.config/ghostty/config" "$repo_root/config/ghostty/config"
sync_file "$HOME/.config/htop/htoprc" "$repo_root/config/htop/htoprc"
sync_file "$HOME/.config/starship.toml" "$repo_root/config/starship/starship.toml"
