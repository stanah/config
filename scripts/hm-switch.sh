#!/usr/bin/env bash
set -euo pipefail

# Standalone home-manager switch (no sudo required)
# Use this for user-level changes (zsh, starship, etc.)
# For system-level changes (launchd, system defaults), use rebuild.sh with sudo.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_DIR"

if [[ "${NIX_CONFIG:-}" != *"experimental-features"* ]]; then
  if [[ -n "${NIX_CONFIG:-}" ]]; then
    NIX_CONFIG="${NIX_CONFIG}"$'\n'"experimental-features = nix-command flakes"
  else
    NIX_CONFIG="experimental-features = nix-command flakes"
  fi
  export NIX_CONFIG
fi

USER_CONFIG="./nix/user-config.nix"
OVERRIDE_ARGS=()
if [ -f "$USER_CONFIG" ]; then
  OVERRIDE_ARGS=(--override-input user-config "path:$USER_CONFIG")
fi

USERNAME=""
if [ -f "$USER_CONFIG" ]; then
  USERNAME="$(nix eval --raw --impure --expr "(import $USER_CONFIG).user" 2>/dev/null || true)"
fi
if [ -z "$USERNAME" ]; then
  USERNAME="$USER"
fi

exec nix run home-manager -- switch --flake ".#${USERNAME}" "${OVERRIDE_ARGS[@]}"
