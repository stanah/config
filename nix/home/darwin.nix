{ config, pkgs, lib, ... }:
{
  # macOS 固有の Home Manager 設定（personal / work 共通）。
  # システムレベルの macOS 設定 (AeroSpace, JankyBorders, Homebrew casks 等) は
  # nix/darwin/ 側にある。

  programs.zsh.profileExtra = ''
    eval "$(/opt/homebrew/bin/brew shellenv)"
  '';

  home.packages = with pkgs; [
    colima # Linux VM for Docker (デーモン側。CLI は common.nix)
  ];
}
