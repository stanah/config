{ config, pkgs, lib, user, ... }:
{
  xdg.enable = true;

  xdg.configFile."ghostty/config".source = ../../config/ghostty/config;
  xdg.configFile."herdr/config.toml".source = ../../config/herdr/config.toml;
  xdg.configFile."htop/htoprc".source = ../../config/htop/htoprc;
  # nvim config is manually symlinked: ln -s ~/work/github.com/stanah/config/config/nvim ~/.config/nvim
  xdg.configFile."mise/config.toml".source = ../../config/mise-global/config.toml;
  xdg.configFile."starship.toml".source = ../../config/starship/starship.toml;

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

        # Update pane/window title with repository name and branch (OSC2; Herdr, cmux, Ghostty tabs)
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

          printf "\033]2;%s\033\\" "$title"
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
        bindkey '\e[103;9~' ghq-fzf  # Cmd+g (via Ghostty)
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
