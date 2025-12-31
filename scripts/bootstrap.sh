#!/usr/bin/env bash
set -euo pipefail

HOST="personal"

if ! command -v nix >/dev/null 2>&1; then
  echo "Nix が見つからないためインストールを開始します。"
  echo "(公式インストーラを実行します)"
  sh <(curl --fail -L https://nixos.org/nix/install) --daemon
  # shellcheck disable=SC1091
  . /etc/profile.d/nix.sh
fi

nix --version

# nix-darwin の初回適用
nix run github:LnL7/nix-darwin -- switch --flake ".#${HOST}"
