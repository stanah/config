#!/usr/bin/env bash
set -euo pipefail

if ! command -v nix >/dev/null 2>&1; then
  echo "Nix が見つからないためインストールを開始します。"
  echo "(公式インストーラを実行します)"
  sh <(curl --fail -L https://nixos.org/nix/install) --daemon
  # shellcheck disable=SC1091
  . /etc/profile.d/nix.sh
fi

nix --version

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

HOST="${1:-}"
if [ -z "$HOST" ] && [ -f "$USER_CONFIG" ]; then
  HOST="$(nix eval --raw --impure --expr "(import $USER_CONFIG).host" 2>/dev/null || true)"
fi
HOST="${HOST:-personal}"

# Determine system type and user
SYSTEM=""
USERNAME=""
if [ -f "$USER_CONFIG" ]; then
  SYSTEM="$(nix eval --raw --impure --expr "(import $USER_CONFIG).system" 2>/dev/null || true)"
  USERNAME="$(nix eval --raw --impure --expr "(import $USER_CONFIG).user" 2>/dev/null || true)"
fi

# Auto-detect system if not specified
if [ -z "$SYSTEM" ]; then
  case "$(uname -s)" in
    Darwin) SYSTEM="aarch64-darwin" ;;
    Linux)  SYSTEM="x86_64-linux" ;;
    *)      echo "Error: Unknown OS: $(uname -s)" >&2; exit 1 ;;
  esac
fi

case "$SYSTEM" in
  *-darwin)
    # nix-darwin の初回適用
    nix run github:LnL7/nix-darwin -- switch --flake ".#${HOST}" "${OVERRIDE_ARGS[@]}"
    ;;
  *-linux)
    # Auto-detect username if not specified
    if [ -z "$USERNAME" ]; then
      USERNAME="${SUDO_USER:-$USER}"
    fi
    # home-manager の初回適用
    nix run github:nix-community/home-manager -- switch --flake ".#${USERNAME}" "${OVERRIDE_ARGS[@]}"
    ;;
  *)
    echo "Error: Unknown system type: $SYSTEM" >&2
    exit 1
    ;;
esac
