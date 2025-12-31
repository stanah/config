{ config, pkgs, lib, user, ... }:
{
  xdg.enable = true;

  home.username = user;
  home.homeDirectory = "/Users/${user}";

  home.stateVersion = "24.05";

  home.sessionVariables = {
    GHQ_ROOT = "${config.home.homeDirectory}/src";
  };

  programs.git = {
    enable = true;
    extraConfig = {
      init.defaultBranch = "main";
      pull.rebase = true;
    };
  };

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    history = {
      path = "${config.xdg.stateHome}/zsh/history";
      size = 100000;
      save = 100000;
    };
    initExtra = ''
      # ghq root shortcut
      cdpath=("$GHQ_ROOT")

      if command -v mise >/dev/null 2>&1; then
        eval "$(mise activate zsh)"
      fi
    '';
  };

  programs.starship.enable = true;
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };
  programs.fzf.enable = true;
  programs.atuin.enable = true;
  programs.sheldon.enable = true;
  programs.gh.enable = true;
  programs.ghq.enable = true;
  programs.zoxide.enable = true;
  programs.eza.enable = true;
  programs.bat.enable = true;
  programs.tmux.enable = true;
  programs.lazygit.enable = true;

  home.packages = with pkgs; [
    dust
    tldr
    yazi
    mise
  ];
}
