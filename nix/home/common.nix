{ config, pkgs, lib, user, ... }:
{
  home.username = user;
  home.homeDirectory = "/Users/${user}";

  home.stateVersion = "24.05";
}
