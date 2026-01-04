#!/usr/bin/env bash
set -euo pipefail

if [[ "${NIX_CONFIG:-}" != *"experimental-features"* ]]; then
  if [[ -n "${NIX_CONFIG:-}" ]]; then
    NIX_CONFIG="${NIX_CONFIG}"$'\n'"experimental-features = nix-command flakes"
  else
    NIX_CONFIG="experimental-features = nix-command flakes"
  fi
  export NIX_CONFIG
fi

HOST="${1:-}"
if [ -z "$HOST" ] && [ -f "./nix/user-config.nix" ]; then
  HOST="$(nix eval --raw --expr '(import ./nix/user-config.nix).host' 2>/dev/null || true)"
fi
HOST="${HOST:-personal}"

exec darwin-rebuild switch --flake ".#${HOST}"
