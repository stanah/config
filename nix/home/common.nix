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
    export PATH="${pkgs.coreutils}/bin:${pkgs.curl}/bin:${pkgs.wget}/bin:${pkgs.perl}/bin:${config.home.homeDirectory}/.local/bin:/usr/bin:/bin:$PATH"

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

  home.activation.nvimTreesitterParsers = lib.hm.dag.entryAfter ["writeBoundary"] ''
    if command -v nvim >/dev/null 2>&1; then
      parser_dir="$HOME/.local/share/nvim/site/parser"
      langs=""
      for lang in markdown markdown_inline html json bash python; do
        if [ ! -f "$parser_dir/''${lang}.so" ]; then
          if [ -z "$langs" ]; then
            langs="'$lang'"
          else
            langs="$langs,'$lang'"
          fi
        fi
      done

      if [ -n "$langs" ]; then
        $DRY_RUN_CMD nvim --headless +"lua require('nvim-treesitter').install({$langs}):wait(300000)" +q
      fi
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

        # Key bindings (macOS/Ghostty向け。terminfo優先 + 代表的なシーケンスの保険)
        zmodload -i zsh/terminfo
        autoload -Uz add-zle-hook-widget

        __bindkey_all() {
          local key=$1 cmd=$2 km
          for km in emacs viins vicmd; do
            bindkey -M $km "$key" "$cmd"
          done
        }

        __bindkey_apply() {
          local up_widget down_widget
          if (( ''${+widgets[history-substring-search-up]} )); then
            up_widget=history-substring-search-up
            down_widget=history-substring-search-down
          else
            up_widget=up-line-or-history
            down_widget=down-line-or-history
          fi
          [[ -n ''${terminfo[khome]} ]] && __bindkey_all "''${terminfo[khome]}" beginning-of-line
          [[ -n ''${terminfo[kend]}  ]] && __bindkey_all "''${terminfo[kend]}"  end-of-line
          [[ -n ''${terminfo[kpp]}   ]] && __bindkey_all "''${terminfo[kpp]}"   beginning-of-buffer-or-history
          [[ -n ''${terminfo[kpn]}   ]] && __bindkey_all "''${terminfo[kpn]}"   end-of-buffer-or-history
          [[ -n ''${terminfo[kich1]} ]] && __bindkey_all "''${terminfo[kich1]}" overwrite-mode
          [[ -n ''${terminfo[kdch1]} ]] && __bindkey_all "''${terminfo[kdch1]}" delete-char
          [[ -n ''${terminfo[kcuu1]} ]] && __bindkey_all "''${terminfo[kcuu1]}" "$up_widget"
          [[ -n ''${terminfo[kcud1]} ]] && __bindkey_all "''${terminfo[kcud1]}" "$down_widget"
          [[ -n ''${terminfo[kcub1]} ]] && __bindkey_all "''${terminfo[kcub1]}" backward-char
          [[ -n ''${terminfo[kcuf1]} ]] && __bindkey_all "''${terminfo[kcuf1]}" forward-char
          [[ -n ''${terminfo[kcbt]}  ]] && __bindkey_all "''${terminfo[kcbt]}"  reverse-menu-complete

          # 端末差分の保険（Ghostty/Terminal/iTerm2でよく出る）
          __bindkey_all '\e[H' beginning-of-line
          __bindkey_all '\eOH' beginning-of-line
          __bindkey_all '\e[F' end-of-line
          __bindkey_all '\eOF' end-of-line
          __bindkey_all '\e[5~' beginning-of-buffer-or-history
          __bindkey_all '\e[6~' end-of-buffer-or-history
          __bindkey_all '\e[2~' overwrite-mode
          __bindkey_all '\e[3~' delete-char
          __bindkey_all '\e[A' "$up_widget"
          __bindkey_all '\e[B' "$down_widget"
          __bindkey_all '\eOA' "$up_widget"
          __bindkey_all '\eOB' "$down_widget"
          __bindkey_all '\e[Z' reverse-menu-complete
        }

        __bindkey_apply

        if (( ''${+functions[add-zle-hook-widget]} )); then
          add-zle-hook-widget zle-line-init __bindkey_apply
          if (( ''${+terminfo[smkx]} )); then
            __keymode_on() { echoti smkx }
            __keymode_off() { echoti rmkx }
            add-zle-hook-widget zle-line-init __keymode_on
            add-zle-hook-widget zle-line-finish __keymode_off
          fi
        fi

        if command -v mise >/dev/null 2>&1; then
          eval "$(mise activate zsh)"
        fi

        if [ -x "${pkgs.sheldon}/bin/sheldon" ]; then
          export SHELDON_CONFIG_DIR="${config.xdg.configHome}/sheldon"
          eval "$("${pkgs.sheldon}/bin/sheldon" source)"
        fi

        __bindkey_apply
      '')
      (lib.mkOrder 1300 ''
        if (( ''${+functions[__bindkey_apply]} )); then
          __bindkey_apply
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
    zellij
    btop
    lazydocker
  ];

  xdg.configFile."sheldon/plugins.toml".text = ''
    shell = "zsh"

    [plugins.fzf-tab]
    github = "Aloxaf/fzf-tab"

    [plugins.zsh-autosuggestions]
    github = "zsh-users/zsh-autosuggestions"

    [plugins.zsh-history-substring-search]
    github = "zsh-users/zsh-history-substring-search"

    [plugins.fast-syntax-highlighting]
    github = "zdharma-continuum/fast-syntax-highlighting"
  '';
}
