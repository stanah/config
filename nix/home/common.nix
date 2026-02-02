{ config, pkgs, lib, user, ... }:
{
  xdg.enable = true;

  xdg.configFile."ghostty/config".source = ../../config/ghostty/config;
  xdg.configFile."htop/htoprc".source = ../../config/htop/htoprc;
  xdg.configFile."nvim".source = ../../config/nvim;
  xdg.configFile."nvim".recursive = true;
  xdg.configFile."mise/config.toml".source = ../../config/mise-global/config.toml;
  xdg.configFile."starship.toml".source = ../../config/starship/starship.toml;
  xdg.configFile."zellij/config.kdl".source = ../../config/zellij/config.kdl;
  xdg.configFile."zellij/layouts".source = ../../config/zellij/layouts;
  xdg.configFile."zellij/layouts".recursive = true;

  home.username = user;
  home.homeDirectory = if pkgs.stdenv.isDarwin then "/Users/${user}" else "/home/${user}";

  home.stateVersion = "24.05";

  # mise manages language runtimes and their PATH (bun, pnpm, foundry, node, etc.)
  # BUN_INSTALL/PNPM_HOME are required for global package installs

  home.sessionVariables = {
    GHQ_ROOT = "${config.home.homeDirectory}/work";
    BUN_INSTALL = "${config.home.homeDirectory}/.bun";
    PNPM_HOME = "${config.home.homeDirectory}/.local/share/pnpm";
    ATUIN_NOBIND = "1";
    EDITOR = "nvim";
    VISUAL = "nvim";
  };

  home.sessionPath = [
    "${config.home.homeDirectory}/.local/bin"
    "${config.home.homeDirectory}/.bun/bin"
    "${config.home.homeDirectory}/.local/share/pnpm"
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
    dotDir = "${config.xdg.configHome}/zsh-nix";  # Nix管理の設定は別ディレクトリへ（~/.zshrcはツールが書き込み可能）
    enableCompletion = true;
    profileExtra = lib.optionalString pkgs.stdenv.isDarwin ''
      eval "$(/opt/homebrew/bin/brew shellenv)"
    '';
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
      # Docker
      dc = "docker compose";
      dps = "docker ps";
      dpsa = "docker ps -a";
      dlog = "docker logs -f";
      dexec = "docker exec -it";
    };
    initContent = lib.mkMerge [
      (lib.mkOrder 500 ''
        # Source home-manager session variables
        if [ -f "${config.home.profileDirectory}/etc/profile.d/hm-session-vars.sh" ]; then
          source "${config.home.profileDirectory}/etc/profile.d/hm-session-vars.sh"
        fi
      '')
      (lib.mkOrder 550 ''
        fpath=(${pkgs.zsh-completions}/share/zsh/site-functions $fpath)
      '')
      (lib.mkOrder 1000 ''
        if [ -f "${config.xdg.configHome}/private/env" ]; then
          source "${config.xdg.configHome}/private/env"
        fi

        # ghq root shortcut (include all ghq repos)
        typeset -aU cdpath
        cdpath=("$GHQ_ROOT")
        if (( $+commands[ghq] )); then
          local -a ghq_repos ghq_parents
          ghq_repos=("''${(@f)$(ghq list -p 2>/dev/null)}")
          ghq_parents=(''${ghq_repos:h})
          cdpath+=($ghq_parents)
        fi

        # completion: distinguish local dirs vs cdpath (ghq) dirs
        zmodload -i zsh/complist
        zstyle ':completion:*' descriptions true
        zstyle ':completion:*:descriptions' format '[%d]'
        zstyle ':completion:*:*:cd:*' group-order local-directories path-directories
        if [[ -n "''${LS_COLORS-}" ]]; then
          zstyle ':completion:*' list-colors ''${(s.:.)LS_COLORS}
        fi
        zstyle ':completion:*:*:cd:*:local-directories' list-colors 'di=1;32'
        zstyle ':completion:*:*:cd:*:path-directories' list-colors 'di=1;36'
        zstyle ':fzf-tab:complete:cd:*' show-group quiet
        zstyle ':fzf-tab:complete:cd:*' group-colors $'\e[32m' $'\e[36m'

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

        # Update pane/window title with repository name and branch (supports Zellij and tmux)
        __update_pane_title() {
          local title
          if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
            local repo_name branch_name
            repo_name=$(basename "$(git rev-parse --show-toplevel 2>/dev/null)")
            branch_name=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
            title="''${repo_name}(''${branch_name})"
          else
            title="''${PWD##*/}"
          fi

          if [ -n "$ZELLIJ" ]; then
            printf "\033]2;%s\033\\" "$title"
          elif [ -n "$TMUX" ]; then
            # workspace-manager 管理ウィンドウは automatic-rename-format に任せる
            local ws_name
            ws_name=$(tmux show-window-option -v @workspace-name 2>/dev/null)
            if [ -z "$ws_name" ]; then
              tmux rename-window "$title"
            fi
          fi
        }
        autoload -Uz add-zsh-hook
        add-zsh-hook precmd __update_pane_title

        __bindkey_apply
      '')
      (lib.mkOrder 1300 ''
        if (( ''${+functions[__bindkey_apply]} )); then
          __bindkey_apply
        fi
      '')
      (lib.mkOrder 1500 ''
        # ユーザーの~/.zshrc（ツールが自由に書き込み可能）
        if [ -f "$HOME/.zshrc" ]; then
          source "$HOME/.zshrc"
        fi
      '')
    ];
  };

  # ~/.zshrcが存在しなければ作成
  home.activation.ensureZshrc = lib.hm.dag.entryAfter ["writeBoundary"] ''
    if [ ! -f "${config.home.homeDirectory}/.zshrc" ]; then
      cat > "${config.home.homeDirectory}/.zshrc" << 'ZSHRC'
# User zsh configuration (tools can write here freely)
# Nix-managed settings are loaded from ~/.config/zsh-nix/.zshrc

ZSHRC
      run echo "Created ~/.zshrc"
    fi
  '';

  programs.tmux = {
    enable = true;
    prefix = "C-Space";
    keyMode = "vi";
    mouse = true;
    baseIndex = 1;
    escapeTime = 0;
    historyLimit = 50000;
    terminal = "tmux-256color";
    plugins = with pkgs.tmuxPlugins; [
      sensible
      yank
      vim-tmux-navigator
      {
        plugin = catppuccin;
        extraConfig = ''
          set -g @catppuccin_window_text ' #W'
          set -g @catppuccin_window_current_text ' #W'
        '';
      }
      resurrect
      continuum
    ];
    extraConfig = ''
      # True color support
      set -ag terminal-overrides ",xterm-256color:RGB"
      set -ag terminal-overrides ",*256col*:Tc"

      # Undercurl support
      set -as terminal-overrides ',*:Smulx=\E[4::%p1%dm'
      set -as terminal-overrides ',*:Setulc=\E[58::2::%p1%{65536}%/%d::%p1%{256}%/%{255}%&%d::%p1%{255}%&%d%;m'

      # Pane splitting (unified with zellij tmux mode: % = right, " = down)
      bind % split-window -h -c "#{pane_current_path}"
      bind '"' split-window -v -c "#{pane_current_path}"
      # Additional intuitive bindings
      bind \\ split-window -h -c "#{pane_current_path}"
      bind | split-window -v -c "#{pane_current_path}"
      bind - split-window -v -c "#{pane_current_path}"
      bind c new-window -c "#{pane_current_path}"

      # Vi-style pane navigation (same as zellij tmux mode h/j/k/l)
      bind h select-pane -L
      bind j select-pane -D
      bind k select-pane -U
      bind l select-pane -R

      # Pane resizing (matches zellij resize mode H/J/K/L = decrease)
      bind -r H resize-pane -L 5
      bind -r J resize-pane -D 5
      bind -r K resize-pane -U 5
      bind -r L resize-pane -R 5

      # Vi copy mode
      bind -T copy-mode-vi v send-keys -X begin-selection
      bind -T copy-mode-vi y send-keys -X copy-selection-and-cancel
      bind -T copy-mode-vi C-v send-keys -X rectangle-toggle

      # === Cmd key support (via Ghostty escape sequences) ===
      # Ghostty sends CSI with modifier 9 (Super) / 10 (Super+Shift)

      # Pane navigation: Cmd+arrows
      set -s user-keys[0] "\e[1;9D"    # Cmd+Left
      set -s user-keys[1] "\e[1;9C"    # Cmd+Right
      set -s user-keys[2] "\e[1;9A"    # Cmd+Up
      set -s user-keys[3] "\e[1;9B"    # Cmd+Down
      bind -n User0 select-pane -L
      bind -n User1 select-pane -R
      bind -n User2 select-pane -U
      bind -n User3 select-pane -D

      # Tab navigation: Cmd+Shift+arrows
      set -s user-keys[4] "\e[1;10D"   # Cmd+Shift+Left
      set -s user-keys[5] "\e[1;10C"   # Cmd+Shift+Right
      bind -n User4 previous-window
      bind -n User5 next-window

      # Pane operations: Cmd+n (split), Cmd+x (close), Cmd+f (zoom)
      set -s user-keys[6] "\e[110;9u"  # Cmd+n
      set -s user-keys[7] "\e[120;9u"  # Cmd+x
      set -s user-keys[8] "\e[102;9u"  # Cmd+f
      bind -n User6 split-window -h -c "#{pane_current_path}"
      bind -n User7 kill-pane
      bind -n User8 resize-pane -Z

      # Tab operations: Cmd+Shift+n (new tab), Cmd+Shift+x (close tab)
      set -s user-keys[9] "\e[110;10u"  # Cmd+Shift+n
      set -s user-keys[10] "\e[120;10u" # Cmd+Shift+x
      bind -n User9 new-window -c "#{pane_current_path}"
      bind -n User10 kill-window

      # Catppuccin theme
      set -g @catppuccin_flavor 'mocha'
      set -g @catppuccin_window_status_style 'rounded'

      # Status bar
      set -g status-position top
      set -g status-interval 5
      set -g status-left-length 30
      set -g status-left "#{E:@catppuccin_status_session}"
      set -g status-right "#{E:@catppuccin_status_application}"
      set -agF status-right "#{E:@catppuccin_status_date_time}"

      # Pane borders
      set -g pane-border-status top
      set -g pane-border-format "#{?pane_active,#[fg=#{@thm_lavender}#,bold] #P  #{pane_current_command}  #{pane_current_path} #[default],#[fg=#{@thm_surface_2}] #P  #{pane_current_command} #[default]}"

      # Window renaming
      # @workspace-name が設定されていればワークスペース名のみ、なければコマンド名
      set -g automatic-rename on
      set -g automatic-rename-format "#{?@workspace-name,#{@workspace-name},#{pane_current_command}}"
      set -g allow-rename on

      # Resurrect & Continuum
      set -g @resurrect-capture-pane-contents 'on'
      set -g @continuum-restore 'on'
      set -g @continuum-save-interval '15'

      # Focus events for neovim
      set -g focus-events on
    '';
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
  programs.home-manager.enable = true;

  home.packages = with pkgs; [
    dust
    tldr
    yazi
    mise
    zsh-completions
    coreutils
    ghq
    gh
    gh-dash
    perl
    zellij
    btop
    lazydocker
    docker
    docker-compose
    unzip
  ] ++ lib.optionals stdenv.isDarwin [
    colima  # macOS only: Linux VM for Docker
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

    [plugins.zsh-shift-select]
    github = "jirutka/zsh-shift-select"
  '';
}
