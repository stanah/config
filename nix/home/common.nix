{ config, pkgs, lib, user, ... }:
{
  xdg.enable = true;

  xdg.configFile."ghostty/config".source = ../../config/ghostty/config;
  xdg.configFile."htop/htoprc".source = ../../config/htop/htoprc;
  xdg.configFile."nvim".source = ../../config/nvim;
  xdg.configFile."nvim".recursive = true;
  xdg.configFile."mise/config.toml".source = ../../config/mise-global/config.toml;
  xdg.configFile."starship.toml".source = ../../config/starship/starship.toml;

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
      export HOME="${config.home.homeDirectory}"
      export USER="${config.home.username}"
      export XDG_CONFIG_HOME="${config.xdg.configHome}"
      $DRY_RUN_CMD ${pkgs.mise}/bin/mise trust --yes "${config.xdg.configHome}/mise/config.toml"
      $DRY_RUN_CMD ${pkgs.mise}/bin/mise install --yes
    fi
  '';

  home.activation.cliToolsInstall = lib.hm.dag.entryAfter ["miseInstall"] ''
    export HOME="${config.home.homeDirectory}"
    export USER="${config.home.username}"
    export XDG_CONFIG_HOME="${config.xdg.configHome}"
    export PATH="${pkgs.curl}/bin:${pkgs.wget}/bin:${pkgs.perl}/bin:${config.home.homeDirectory}/.local/bin:$PATH"

    if ! command -v claude >/dev/null 2>&1; then
      $DRY_RUN_CMD ${pkgs.curl}/bin/curl -fsSL https://claude.ai/install.sh | /bin/bash
    fi

    if ! command -v cursor-agent >/dev/null 2>&1; then
      $DRY_RUN_CMD ${pkgs.curl}/bin/curl -fsSL https://cursor.com/install | /bin/bash
    fi

    if ! command -v coderabbit >/dev/null 2>&1; then
      $DRY_RUN_CMD ${pkgs.curl}/bin/curl -fsSL https://cli.coderabbit.ai/install.sh | /bin/sh
    fi
  '';

  home.sessionPath = [
    "${config.home.homeDirectory}/.local/bin"
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
      npm = "pnpm";
      yarn = "pnpm";
      yarnpkg = "pnpm";
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

        # Delete key (forward delete)
        bindkey '\e[3~' delete-char

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
    perl
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
