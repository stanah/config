{ config, pkgs, lib, user, ... }:
{
  xdg.enable = true;

  xdg.configFile."ghostty/config".source = ../../config/ghostty/config;
  xdg.configFile."htop/htoprc".source = ../../config/htop/htoprc;
  xdg.configFile."nvim".source = ../../config/nvim;
  xdg.configFile."nvim".recursive = true;
  xdg.configFile."mise/config.toml".source = ../../config/mise/config.toml;

  home.username = user;
  home.homeDirectory = if pkgs.stdenv.isDarwin then "/Users/${user}" else "/home/${user}";

  home.stateVersion = "24.05";

  home.sessionVariables = {
    GHQ_ROOT = "${config.home.homeDirectory}/work";
    BUN_INSTALL = "${config.home.homeDirectory}/.bun";
    ATUIN_NOBIND = "1";
    EDITOR = "nvim";
    VISUAL = "nvim";
  };

  home.activation.miseInstall = lib.hm.dag.entryAfter ["writeBoundary"] ''
    if [ -x "${pkgs.mise}/bin/mise" ]; then
      $DRY_RUN_CMD ${pkgs.mise}/bin/mise install --yes
    fi
  '';

  home.sessionPath = [
    "${config.home.homeDirectory}/.bun/bin"
    "${config.home.homeDirectory}/.foundry/bin"
    "${config.home.homeDirectory}/.claude/local"
  ];

  programs.git = {
    enable = true;
    includes = [
      { path = "${config.xdg.configHome}/private/gitconfig"; }
    ];
    settings = {
      init.defaultBranch = "main";
      pull.rebase = true;
      core.editor = "nvim";
      alias = {
        lg = "log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit --date=relative";
        lga = "log --graph --all --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit --date=relative";
      };
    };
  };

  programs.zsh = {
    enable = true;
    dotDir = config.home.homeDirectory;
    enableCompletion = true;
    autosuggestion.enable = false;
    syntaxHighlighting.enable = false;
    history = {
      path = "${config.xdg.stateHome}/zsh/history";
      size = 100000;
      save = 100000;
    };
    shellAliases = {
      ls = "eza --icons --git";
      ll = "eza -l --icons --git";
      la = "eza -la --icons --git";
      cat = "bat";
      g = "git";
      lg = "lazygit";
      claude = "${config.home.homeDirectory}/.claude/local/claude";
      ".." = "cd ..";
      "..." = "cd ../..";
    };
    initContent = lib.mkMerge [
      (lib.mkOrder 550 ''
        fpath=(${pkgs.zsh-completions}/share/zsh/site-functions $fpath)
      '')
      (lib.mkOrder 1000 ''
        if [ -f "${config.xdg.configHome}/private/env" ]; then
          source "${config.xdg.configHome}/private/env"
        fi

        # ghq root shortcut
        cdpath=("$GHQ_ROOT")

        setopt inc_append_history
        setopt share_history
        setopt hist_ignore_all_dups
        setopt hist_reduce_blanks
        setopt extended_glob
        setopt no_beep

        if command -v mise >/dev/null 2>&1; then
          eval "$(mise activate zsh)"
        fi

        if command -v sheldon >/dev/null 2>&1; then
          eval "$(sheldon source)"
        fi
      '')
    ];
  };

  programs.starship.enable = true;
  programs.neovim = {
    enable = true;
    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;
  };
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };
  programs.atuin.enable = true;
  programs.sheldon.enable = true;
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
    zsh-completions
    ghq
    gh
  ];

  xdg.configFile."sheldon/plugins.toml".text = ''
    shell = "zsh"

    [plugins.fzf-tab]
    github = "Aloxaf/fzf-tab"

    [plugins.zsh-autosuggestions]
    github = "zsh-users/zsh-autosuggestions"

    [plugins.fast-syntax-highlighting]
    github = "zdharma-continuum/fast-syntax-highlighting"
  '';
}
