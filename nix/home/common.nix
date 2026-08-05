{ config, pkgs, lib, user, ... }:
{
  xdg.enable = true;

  xdg.configFile."ghostty/config".source = ../../config/ghostty/config;
  xdg.configFile."herdr/config.toml".source = ../../config/herdr/config.toml;
  xdg.configFile."htop/htoprc".source = ../../config/htop/htoprc;
  # nvim config is manually symlinked: ln -s ~/work/github.com/stanah/config/config/nvim ~/.config/nvim
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
    # ロケールを UTF-8 にしないと日本語がバイト列 (<E3><83>...) で表示される
    LANG = "en_US.UTF-8";
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

  # ~/.zshenvはNix管理外にして書き込み可能にする（~/.zshrcと同じパターン）
  home.file.".zshenv".enable = false;

  programs.zsh = {
    enable = true;
    dotDir = "${config.xdg.configHome}/zsh-nix";  # Nix管理の設定は別ディレクトリへ（~/.zshrc, ~/.zshenvはツールが書き込み可能）
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
      # Docker
      dc = "docker compose";
      dps = "docker ps";
      dpsa = "docker ps -a";
      dlog = "docker logs -f";
      dexec = "docker exec -it";
    };
    initContent = lib.mkMerge [
      (lib.mkOrder 500 ''
        # Remove ~/.nix-profile/bin from PATH — home-manager uses /etc/profiles/per-user/ instead,
        # and the empty ~/.nix-profile causes "no such file" errors for starship, mise, etc.
        path=("''${(@)path:#$HOME/.nix-profile/bin}")

        # Source home-manager session variables
        if [ -f "${config.home.profileDirectory}/etc/profile.d/hm-session-vars.sh" ]; then
          source "${config.home.profileDirectory}/etc/profile.d/hm-session-vars.sh"
        fi
      '')
      (lib.mkOrder 550 ''
        fpath=(${pkgs.zsh-completions}/share/zsh/site-functions $fpath)

        # pnpm tab completion
        eval "$(pnpm completion zsh)"
      '')
      (lib.mkOrder 1000 ''
        if [ -f "${config.xdg.configHome}/private/env" ]; then
          source "${config.xdg.configHome}/private/env"
        fi

        # ghq + fzf: fuzzy-find and cd into a ghq repository
        function ghq-fzf() {
          local repo
          repo=$(ghq list | fzf --preview "bat --color=always --style=plain $(ghq root)/{}/README.md 2>/dev/null || eza --icons --git -la $(ghq root)/{}" --preview-window=right:50%)
          if [[ -n "$repo" ]]; then
            BUFFER="cd -- $(ghq root)/$repo"
            zle accept-line
          fi
          zle reset-prompt
        }
        zle -N ghq-fzf

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
        zstyle ':completion:*' menu no
        zstyle ':completion:*:*:cd:*' group-order local-directories path-directories
        if [[ -n "''${LS_COLORS-}" ]]; then
          zstyle ':completion:*' list-colors ''${(s.:.)LS_COLORS}
        fi
        zstyle ':completion:*:*:cd:*:local-directories' list-colors 'di=1;32'
        zstyle ':completion:*:*:cd:*:path-directories' list-colors 'di=1;35'

        # fzf-tab: global display settings
        zstyle ':fzf-tab:*' fzf-flags \
          --height=60% \
          --border=rounded \
          --padding=0,1 \
          --bind=tab:down
        zstyle ':fzf-tab:*' use-fzf-default-opts no
        zstyle ':fzf-tab:*' switch-group '<' '>'
        zstyle ':fzf-tab:*' show-group brief
        zstyle ':fzf-tab:*' prefix ""
        zstyle ':fzf-tab:*' group-colors \
          $'\e[94m' $'\e[32m' $'\e[33m' $'\e[35m' $'\e[31m' $'\e[36m'
        # fzf-tab: cd preview
        zstyle ':fzf-tab:complete:cd:*' show-group quiet
        zstyle ':fzf-tab:complete:cd:*' group-colors $'\e[32m' $'\e[35m'
        zstyle ':fzf-tab:complete:cd:*' fzf-preview \
          '[[ -d $realpath ]] && eza -1 --color=always --icons $realpath || { found=$(find $GHQ_ROOT -maxdepth 3 -type d -name $word 2>/dev/null | head -1); [[ -n $found ]] && eza -1 --color=always --icons $found; }'

        # fzf-tab: file/directory preview
        zstyle ':fzf-tab:complete:ls:*' fzf-preview 'eza -1 --color=always --icons $realpath'

        # fzf-tab: process preview (kill/ps)
        zstyle ':completion:*:*:*:*:processes' command "ps -u $USER -o pid,user,comm -w -w"
        zstyle ':fzf-tab:complete:(kill|ps):argument-rest' fzf-preview \
          '[[ $group == "[process ID]" ]] && ps -p $word -o pid,user,%cpu,%mem,command -w -w'
        zstyle ':fzf-tab:complete:(kill|ps):argument-rest' fzf-flags --preview-window=down:4:wrap

        # fzf-tab: environment variable preview
        zstyle ':fzf-tab:complete:(-command-|-parameter-|-brace-parameter-|export|unset|expand):*' \
          fzf-preview 'echo ''${(P)word}'

        # fzf-tab: git previews
        zstyle ':fzf-tab:complete:git-(add|diff|restore):*' fzf-preview 'git diff $word | delta'
        zstyle ':fzf-tab:complete:git-log:*' fzf-preview 'git log --color=always $word'
        zstyle ':fzf-tab:complete:git-checkout:*' fzf-preview \
          'case "$group" in
          "modified file") git diff $word | delta ;;
          "recent commit object name") git show --color=always $word | delta ;;
          *) git log --color=always $word ;;
          esac'

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

        # Update pane/window title with repository name and branch (supports cmux, Zellij, and tmux)
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
            # pane_titleをクリア（エージェントが自由に設定できるようにする）
            printf '\033]2;\033\\'
            # window変数に書き込み、automatic-rename-format で表示する
            tmux set-window-option @tab-title "$title"
          elif [ -n "$CMUX_WORKSPACE_ID" ]; then
            printf "\033]2;%s\033\\" "$title"
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
      (lib.mkOrder 1400 ''
        # Keybindings that must be set after __bindkey_apply (mkOrder 1300)
        bindkey '^g' ghq-fzf
        bindkey '\e[103;9~' ghq-fzf  # Cmd+g (via Ghostty/tmux)
      '')
      (lib.mkOrder 1500 ''
        # ユーザーの~/.zshrc（ツールが自由に書き込み可能）
        if [ -f "$HOME/.zshrc" ]; then
          source "$HOME/.zshrc"
        fi
      '')
    ];
  };

  # ~/.zshenvが存在しなければ作成（ツールが自由に書き込み可能）
  home.activation.ensureZshenv = lib.hm.dag.entryAfter ["writeBoundary"] ''
    if [ ! -f "${config.home.homeDirectory}/.zshenv" ]; then
      cat > "${config.home.homeDirectory}/.zshenv" << 'ZSHENV'
# User zsh environment (tools can write here freely)
# Nix-managed settings are loaded from ~/.config/zsh-nix/.zshenv
source "${config.xdg.configHome}/zsh-nix/.zshenv"

ZSHENV
      run echo "Created ~/.zshenv"
    fi
  '';

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

  programs.tmux = let
    paneLabel = pkgs.writeShellScript "tmux-pane-label" ''
      dir="$1"
      if cd "$dir" 2>/dev/null && git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        repo=$(basename "$(git rev-parse --show-toplevel)")
        branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
        echo "''${repo}(''${branch})"
      else
        basename "$dir"
      fi
    '';
  in {
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

      # Note: extended-keys intentionally off; Cmd+key uses custom CSI ~ sequences via user-keys

      # Undercurl support
      set -as terminal-overrides ',*:Smulx=\E[4::%p1%dm'
      set -as terminal-overrides ',*:Setulc=\E[58::2::%p1%{65536}%/%d::%p1%{256}%/%{255}%&%d::%p1%{255}%&%d%;m'

      # Pane splitting (unified with zellij tmux mode: % = right, " = down)
      bind % split-window -h -c "#{pane_current_path}"
      bind '"' split-window -v -c "#{pane_current_path}"
      # Additional intuitive bindings
      bind | split-window -h -c "#{pane_current_path}"
      bind - split-window -v -c "#{pane_current_path}"
      bind c new-window -c "#{pane_current_path}"

      # Vi-style pane navigation (same as zellij tmux mode h/j/k/l, no wrap)
      bind h if -F '#{pane_at_left}' "" 'select-pane -L'
      bind j if -F '#{pane_at_bottom}' "" 'select-pane -D'
      bind k if -F '#{pane_at_top}' "" 'select-pane -U'
      bind l if -F '#{pane_at_right}' "" 'select-pane -R'

      # Pane resizing (matches zellij resize mode H/J/K/L = decrease)
      bind -r H resize-pane -L 5
      bind -r J resize-pane -D 5
      bind -r K resize-pane -U 5
      bind -r L resize-pane -R 5

      # Mouse: double-click = equalize panes, triple-click = cycle layout
      bind -T root DoubleClick1Pane select-layout -E
      bind -T root TripleClick1Pane next-layout

      # Vi copy mode
      bind -T copy-mode-vi v send-keys -X begin-selection
      bind -T copy-mode-vi y send-keys -X copy-selection-and-cancel
      bind -T copy-mode-vi C-v send-keys -X rectangle-toggle

      # Mouse drag selection → clipboard copy
      ${if pkgs.stdenv.isDarwin then ''
        bind -T copy-mode-vi MouseDragEnd1Pane send-keys -X copy-pipe-and-cancel "pbcopy"
      '' else ''
        # Linux (WSL 前提): OSC52 + clip.exe。clip.exe が無い環境では OSC52 のみ
        set -g set-clipboard on
        bind -T copy-mode-vi MouseDragEnd1Pane send-keys -X copy-pipe-and-cancel "command -v clip.exe >/dev/null && clip.exe || cat >/dev/null"
      ''}

      # === Cmd key support (via Ghostty escape sequences) ===
      # Ghostty sends CSI with modifier 9 (Super) / 10 (Super+Shift)

      # Pane navigation: Cmd+arrows (no wrap)
      set -s user-keys[0] "\e[1;9D"    # Cmd+Left
      set -s user-keys[1] "\e[1;9C"    # Cmd+Right
      set -s user-keys[2] "\e[1;9A"    # Cmd+Up
      set -s user-keys[3] "\e[1;9B"    # Cmd+Down
      bind -n User0 if -F '#{pane_at_left}' "" 'select-pane -L'
      bind -n User1 if -F '#{pane_at_right}' "" 'select-pane -R'
      bind -n User2 if -F '#{pane_at_top}' "" 'select-pane -U'
      bind -n User3 if -F '#{pane_at_bottom}' "" 'select-pane -D'
      # Pane navigation: Cmd+i/j/k/l (no wrap)
      set -s user-keys[13] "\e[105;9~"   # Cmd+i
      set -s user-keys[14] "\e[106;9~"   # Cmd+j
      set -s user-keys[15] "\e[107;9~"   # Cmd+k
      set -s user-keys[16] "\e[108;9~"   # Cmd+l
      bind -n User13 if -F '#{pane_at_top}' "" 'select-pane -U'
      bind -n User14 if -F '#{pane_at_left}' "" 'select-pane -L'
      bind -n User15 if -F '#{pane_at_bottom}' "" 'select-pane -D'
      bind -n User16 if -F '#{pane_at_right}' "" 'select-pane -R'

      # Tab navigation: Cmd+Shift+arrows / Cmd+Shift+j/l (no wrap)
      set -s user-keys[4] "\e[1;10D"   # Cmd+Shift+Left
      set -s user-keys[5] "\e[1;10C"   # Cmd+Shift+Right
      set -s user-keys[19] "\e[106;10~"  # Cmd+Shift+j
      set -s user-keys[20] "\e[108;10~"  # Cmd+Shift+l
      bind -n User4 if-shell "test #{window_index} != $(tmux list-windows -F '##{window_index}' | head -1)" previous-window
      bind -n User5 if-shell "test #{window_index} != $(tmux list-windows -F '##{window_index}' | tail -1)" next-window
      bind -n User19 if-shell "test #{window_index} != $(tmux list-windows -F '##{window_index}' | head -1)" previous-window
      bind -n User20 if-shell "test #{window_index} != $(tmux list-windows -F '##{window_index}' | tail -1)" next-window

      # Pane operations: Cmd+n (split), Cmd+x (close), Cmd+f (zoom)
      set -s user-keys[6] "\e[110;9~"  # Cmd+n
      set -s user-keys[7] "\e[120;9~"  # Cmd+x
      set -s user-keys[8] "\e[102;9~"  # Cmd+f
      bind -n User6 split-window -h -c "#{pane_current_path}"
      bind -n User7 kill-pane
      bind -n User8 resize-pane -Z

      # ghq fuzzy finder: Cmd+g → send Ctrl+g to trigger zsh widget
      set -s user-keys[11] "\e[103;9~" # Cmd+g
      bind -n User11 send-keys C-g

      # Pane split: Cmd+d (horizontal), Cmd+Shift+d (vertical)
      set -s user-keys[17] "\e[100;9~"   # Cmd+d
      set -s user-keys[18] "\e[100;10~"  # Cmd+Shift+d
      bind -n User17 split-window -h -c "#{pane_current_path}"
      bind -n User18 split-window -v -c "#{pane_current_path}"

      # Tab operations: Cmd+Shift+n (new tab), Cmd+Shift+x (close tab)
      set -s user-keys[9] "\e[110;10~"  # Cmd+Shift+n
      set -s user-keys[10] "\e[120;10~" # Cmd+Shift+x
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
      # pane_current_path から repo(branch) を取得するヘルパー（status-interval ごとに自動更新）
      set -g pane-border-status top
      set -g pane-active-border-style "fg=#{@thm_lavender}"
      set -g pane-border-style "fg=#{@thm_surface_1}"
      set -g pane-border-format "#{?pane_active,#[fg=#{@thm_lavender}#,bold] ● #P  #[fg=#{@thm_green}#,bold]#(${paneLabel} #{pane_current_path})#{?#{pane_title}, #[fg=#{@thm_peach}#,bold]#{pane_title},}  #[fg=#{@thm_lavender}#,bold]#{pane_current_command} #[default],#[fg=#{@thm_surface_2}#,dim]   #P  #[fg=#{@thm_green}#,dim]#(${paneLabel} #{pane_current_path})#{?#{pane_title}, #[fg=#{@thm_peach}#,dim]#{pane_title},}  #[fg=#{@thm_lavender}#,dim]#{pane_current_command} #[default]}"

      # Active pane: opaque background to stand out
      # Non-active panes: transparent (terminal default) to recede
      set -g window-style "bg=default"
      set -g window-active-style "bg=#121212"

      # Window renaming
      # @tab-title（precmdで設定）があればそれを、なければコマンド名を表示
      set -g automatic-rename on
      set -g automatic-rename-format "#{?@tab-title,#{@tab-title},#{pane_current_command}}"
      set -g allow-rename on

      # Resurrect & Continuum
      set -g @resurrect-capture-pane-contents 'on'
      set -g @continuum-restore 'on'
      set -g @continuum-save-interval '15'

      # Focus events for neovim
      set -g focus-events on

      # Gather/Scatter: Cmd+\ で AI エージェント系ペインを一時集約/復帰
      set -s user-keys[12] "\e[92;9~"
      bind -n User12 run-shell "${pkgs.writeShellScript "tmux-gather" ''
        TARGETS="claude|kiro|codex|aider|cursor"
        overview_win=$(tmux show-environment -g GATHER_OVERVIEW_WIN 2>/dev/null | cut -d= -f2)

        if [ -n "$overview_win" ] && tmux list-windows -F "#{window_id}" | grep -qF "$overview_win"; then
          # === Scatter ===
          mapping=$(tmux show-environment -g GATHER_MAPPING 2>/dev/null | cut -d= -f2-)
          layouts=$(tmux show-environment -g GATHER_LAYOUTS 2>/dev/null | cut -d= -f2-)
          pane_orders=$(tmux show-environment -g GATHER_PANE_ORDERS 2>/dev/null | cut -d= -f2-)
          IFS="|"
          for entry in $mapping; do
            p_id=$(echo "$entry" | cut -d, -f1)
            w_id=$(echo "$entry" | cut -d, -f2)
            if tmux list-panes -t "$p_id" -F "#{pane_id}" 2>/dev/null | grep -q .; then
              tmux move-pane -d -s "$p_id" -t "$w_id" 2>/dev/null
            fi
          done
          # Kill placeholder panes that kept windows alive during gather
          placeholders=$(tmux show-environment -g GATHER_PLACEHOLDERS 2>/dev/null | cut -d= -f2-)
          for ph in $placeholders; do
            [ -n "$ph" ] && tmux kill-pane -t "$ph" 2>/dev/null
          done
          # Restore original pane order per window
          echo "$pane_orders" | tr '|' '\n' > /tmp/tmux-gather-orders
          while IFS= read -r oentry; do
            o_wid=$(echo "$oentry" | cut -d= -f1)
            o_order=$(echo "$oentry" | cut -d= -f2-)
            idx=0
            IFS=' '
            for expected_pane in $(echo "$o_order" | tr ',' ' '); do
              current_pane=$(tmux list-panes -t "$o_wid" -F "#{pane_id}" 2>/dev/null | sed -n "$((idx+1))p")
              if [ -n "$current_pane" ] && [ "$current_pane" != "$expected_pane" ]; then
                tmux swap-pane -d -s "$expected_pane" -t "$current_pane" 2>/dev/null
              fi
              idx=$((idx+1))
            done
          done < /tmp/tmux-gather-orders
          # Restore original layouts
          echo "$layouts" | tr '|' '\n' > /tmp/tmux-gather-layouts
          while IFS= read -r lentry; do
            l_wid=$(echo "$lentry" | cut -d, -f1)
            l_layout=$(echo "$lentry" | cut -d, -f2-)
            tmux select-layout -t "$l_wid" "$l_layout" 2>/dev/null
          done < /tmp/tmux-gather-layouts
          rm -f /tmp/tmux-gather-orders /tmp/tmux-gather-layouts
          remaining=$(tmux list-panes -t "$overview_win" -F x 2>/dev/null | wc -l | tr -d ' ')
          if [ "''${remaining:-0}" -gt 0 ]; then
            tmux rename-window -t "$overview_win" "orphaned-panes"
            tmux display-message "Scattered ($remaining orphaned panes remain)"
          else
            tmux kill-window -t "$overview_win" 2>/dev/null
            tmux display-message "Panes scattered back"
          fi
          tmux set-environment -g -u GATHER_OVERVIEW_WIN
          tmux set-environment -g -u GATHER_MAPPING
          tmux set-environment -g -u GATHER_LAYOUTS
          tmux set-environment -g -u GATHER_PANE_ORDERS
          tmux set-environment -g -u GATHER_PLACEHOLDERS
        else
          # === Gather ===
          mapping=""
          pane_ids=""
          layouts=""
          pane_orders=""
          saved_windows=""
          all_procs=$(ps -eo pid=,ppid=,args=)

          for pane_info in $(tmux list-panes -s -F "#{pane_id}:#{pane_pid}:#{window_id}"); do
            pid=$(echo "$pane_info" | cut -d: -f2)
            found=$(echo "$all_procs" | awk -v root="$pid" -v pat="$TARGETS" '
              {
                pp[$1]=$2
                n=split($3,a,"/"); bn[$1]=a[n]
                arg2[$1]=""
                if(substr($4,1,1)=="/") arg2[$1]=$4
              }
              END {
                pids[root]=1
                for(pass=0;pass<5;pass++){
                  changed=0
                  for(p in pp){
                    if((p in pids)==0 && (pp[p] in pids)){
                      pids[p]=1; changed=1
                    }
                  }
                  if(changed==0) break
                }
                for(p in pids){
                  if(tolower(bn[p]) ~ pat || tolower(arg2[p]) ~ pat){
                    print bn[p]; exit
                  }
                }
              }
            ')
            if [ -n "$found" ]; then
              p_id=$(echo "$pane_info" | cut -d: -f1)
              w_id=$(echo "$pane_info" | cut -d: -f3)
              mapping="''${mapping:+$mapping|}$p_id,$w_id"
              pane_ids="$pane_ids $p_id"
              # Save window layout and pane order (once per window)
              case "$saved_windows" in
                *"$w_id"*) ;;
                *)
                  w_layout=$(tmux display-message -t "$w_id" -p "#{window_layout}")
                  layouts="''${layouts:+$layouts|}$w_id,$w_layout"
                  w_panes=$(tmux list-panes -t "$w_id" -F "#{pane_id}" | tr '\n' ',' | sed 's/,$//')
                  pane_orders="''${pane_orders:+$pane_orders|}$w_id=$w_panes"
                  saved_windows="$saved_windows $w_id"
                  ;;
              esac
            fi
          done

          if [ -z "$pane_ids" ]; then
            tmux display-message "No agent panes found"
            exit 0
          fi

          # Create placeholder panes for windows that would become empty
          placeholders=""
          for w_id in $(echo "$mapping" | tr '|' '\n' | cut -d, -f2 | sort -u); do
            total=$(tmux list-panes -t "$w_id" -F x 2>/dev/null | wc -l | tr -d ' ')
            agents=$(echo "$mapping" | tr '|' '\n' | grep ",$w_id$" | wc -l | tr -d ' ')
            if [ "$total" -le "$agents" ]; then
              ph=$(tmux split-window -d -t "$w_id" -P -F "#{pane_id}" "sleep infinity")
              placeholders="''${placeholders:+$placeholders|}$ph"
            fi
          done

          overview_win=$(tmux new-window -d -n "agents-overview" -P -F "#{window_id}")
          default_pane=$(tmux list-panes -t "$overview_win" -F "#{pane_id}" | head -1)
          first=1
          for p_id in $pane_ids; do
            if [ "$first" = 1 ]; then
              tmux move-pane -d -s "$p_id" -t "$overview_win"
              tmux kill-pane -t "$default_pane" 2>/dev/null
              first=0
            else
              tmux join-pane -d -s "$p_id" -t "$overview_win" 2>/dev/null \
                || tmux join-pane -dh -s "$p_id" -t "$overview_win" 2>/dev/null
            fi
            tmux select-layout -t "$overview_win" tiled 2>/dev/null
          done
          tmux set-environment -g GATHER_OVERVIEW_WIN "$overview_win"
          tmux set-environment -g GATHER_MAPPING "$mapping"
          tmux set-environment -g GATHER_LAYOUTS "$layouts"
          tmux set-environment -g GATHER_PANE_ORDERS "$pane_orders"
          tmux set-environment -g GATHER_PLACEHOLDERS "$placeholders"
          tmux select-window -t "$overview_win"
          count=$(tmux list-panes -t "$overview_win" -F x 2>/dev/null | wc -l | tr -d " ")
          tmux display-message "Gathered $count agent panes"
        fi
      ''}"
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
    glow
    htop  # 設定は config/htop/htoprc で配布
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
