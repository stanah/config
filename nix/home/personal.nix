{ config, pkgs, lib, ... }:
{
  home.sessionVariables = {
    NARGO_HOME = "${config.home.homeDirectory}/.nargo";
  };

  home.sessionPath = [
    "${config.home.homeDirectory}/.nargo/bin"
    "${config.home.homeDirectory}/.lmstudio/bin"
    "${config.home.homeDirectory}/.antigravity/antigravity/bin"
  ];

  programs.zsh.shellAliases = {
    tm = "task-master";
    taskmaster = "task-master";
    hamster = "task-master";
    ham = "task-master";
  };

  home.packages = with pkgs; [
    chezmoi
  ];
}
