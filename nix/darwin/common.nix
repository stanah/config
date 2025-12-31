{ config, pkgs, lib, user, ... }:
{
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nix.gc = {
    automatic = true;
    interval = { Weekday = 0; Hour = 3; Minute = 0; };
    options = "--delete-older-than 30d";
  };

  # Allow nix-darwin to know the user's home directory.
  users.users.${user}.home = "/Users/${user}";

  programs.zsh.enable = true;

  environment.systemPackages = with pkgs; [
    git
    gnupg
    ripgrep
    fd
  ];

  # nix-darwin uses a numeric stateVersion. Avoid changing this once set.
  system.stateVersion = 5;
}
