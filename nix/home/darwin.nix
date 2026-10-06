{ config, pkgs, lib, ... }:
{
  # macOS 固有の Home Manager 設定（personal / work 共通）。
  # システムレベルの macOS 設定 (AeroSpace, JankyBorders, Homebrew casks, キーボード等) は
  # nix/darwin/ 側にある。

  programs.zsh.profileExtra = ''
    eval "$(/opt/homebrew/bin/brew shellenv)"
  '';

  # Karabiner-Elements は karabiner.json を自身で書き換えるため、Nix store への
  # symlink ではなく書き込み可能なコピーとして配置する。
  # GUI で変更した内容は ./scripts/sync-config.sh でリポジトリへ回収する。
  home.activation.karabinerConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    karabiner_src="${../../config/karabiner/karabiner.json}"
    karabiner_dest="${config.xdg.configHome}/karabiner/karabiner.json"
    run mkdir -p "$(dirname "$karabiner_dest")"
    if ! cmp -s "$karabiner_src" "$karabiner_dest"; then
      if [ -e "$karabiner_dest" ] || [ -L "$karabiner_dest" ]; then
        run mv -f "$karabiner_dest" "$karabiner_dest.before-nix"
      fi
      run install -m 644 "$karabiner_src" "$karabiner_dest"
    fi
  '';

  home.packages = with pkgs; [
    colima # Linux VM for Docker (デーモン側。CLI は common.nix)
  ];
}
