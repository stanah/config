{ config, pkgs, lib, ... }:
{
  programs.git.enable = true;
  programs.zsh.enable = true;

  home.packages = with pkgs; [
    chezmoi
    starship
  ];

  programs.starship.enable = true;
}
