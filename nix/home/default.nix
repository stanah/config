{ config, pkgs, lib, user, ... }:
{
  home.username = user;
  home.homeDirectory = "/Users/${user}";

  home.stateVersion = "24.05";

  programs.git.enable = true;
  programs.zsh.enable = true;

  home.packages = with pkgs; [
    chezmoi
    starship
  ];

  programs.starship.enable = true;
}
