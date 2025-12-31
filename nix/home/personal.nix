{ config, pkgs, lib, ... }:
{
  home.packages = with pkgs; [
    chezmoi
  ];
}
