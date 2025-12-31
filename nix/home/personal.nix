{ config, pkgs, lib, ... }:
{
  programs.zsh.initExtraBeforeCompInit = lib.mkBefore ''
    # Kiro CLI pre block. Keep at the top of this file.
    [[ -f "${config.home.homeDirectory}/Library/Application Support/kiro-cli/shell/zshrc.pre.zsh" ]] \
      && builtin source "${config.home.homeDirectory}/Library/Application Support/kiro-cli/shell/zshrc.pre.zsh"
  '';

  programs.zsh.initExtra = lib.mkAfter ''
    # Kiro CLI post block. Keep at the bottom of this file.
    [[ -f "${config.home.homeDirectory}/Library/Application Support/kiro-cli/shell/zshrc.post.zsh" ]] \
      && builtin source "${config.home.homeDirectory}/Library/Application Support/kiro-cli/shell/zshrc.post.zsh"
  '';

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
