# config

nix-darwin + home-manager で macOS と WSL2 Ubuntu の環境を管理するリポジトリです。

## 対応環境

| host プロファイル | 環境 | system |
|---|---|---|
| `personal` | 個人 Mac | `aarch64-darwin` |
| `work` | 業務 Mac | `aarch64-darwin` |
| `ubuntu` | WSL2 Ubuntu（GPU なし） | `x86_64-linux` |
| `gpu-server` | WSL2 Ubuntu（NVIDIA GPU） | `x86_64-linux` |

`host` と `system` の OS が一致しない場合は評価エラーになります。

## セットアップ

共通の準備として、`nix/user-config.example.nix` を `nix/user-config.nix` にコピーし、`user` / `host` / `system` を環境に合わせます（このファイルは Git 管理外です）。

### macOS

```sh
sudo -H ./scripts/bootstrap.sh
```

Nix が無ければインストールし、nix-darwin を初回適用します。
`sudo -H` は root の `HOME` を使うために必要です（`$HOME is not owned by you` エラー回避）。

### Ubuntu (WSL2)

systemd の有効化、ロケール生成、ログインシェル変更、Docker Engine、GPU（nvidia-container-toolkit）といった OS 側の準備が先に必要です。
手順は `docs/ubuntu.md` を参照してください。
OS 側の準備後は macOS と同様に `./scripts/bootstrap.sh` を実行します（Linux では home-manager の適用まで行われます。sudo 不要）。

## 日常操作

- ユーザー設定の反映（zsh, starship 等。sudo 不要）: `./scripts/hm-switch.sh`
- macOS のシステム設定を含む再構築（launchd, system defaults 等）: `sudo -H ./scripts/rebuild.sh`
- 実機で直接編集した設定をリポジトリへ回収: `./scripts/sync-config.sh` の後に `git add` / `git commit`

## 構成

```text
nix/
├── darwin/            # macOS システム設定 (AeroSpace, JankyBorders, Homebrew casks)
│   ├── common.nix
│   ├── personal.nix
│   └── work.nix
└── home/              # Home Manager 設定
    ├── common.nix        # 全 OS 共通 (zsh, CLI ツール, docker CLI, mise)
    ├── darwin.nix        # macOS 共通 (colima, brew shellenv)
    ├── personal.nix      # 個人 Mac 固有
    ├── work.nix          # 業務 Mac 固有
    ├── linux-common.nix  # WSL2 Ubuntu 共通 (ロケール, 描画用フォント)
    ├── ubuntu.nix        # 通常 Ubuntu 固有
    └── gpu-server.nix    # GPU マシン固有 (nvidia-smi エイリアス)
```

配布される設定ファイルは `config/` 以下にあります。

- `config/ghostty/config`
- `config/herdr/config.toml`
- `config/htop/htoprc`
- `config/mise-global/config.toml`
- `config/starship/starship.toml`
- `config/nvim/`（Home Manager 管理外。`ln -s <repo>/config/nvim ~/.config/nvim` で手動リンク）

ターミナルマルチプレクサは Herdr に一本化しています（tmux と zellij は廃止済み）。

## 秘密情報

API キーや Git の個人情報は Git 管理外の `~/.config/private/` に置きます。

```sh
mkdir -p ~/.config/private
cp config/private.env.example ~/.config/private/env
vim ~/.config/private/env   # 実際の値を設定
```

- `~/.config/private/env`: zsh 起動時に自動で読み込まれます。
- `~/.config/private/gitconfig`: git 設定に include されます（書式は `docs/tools.md` を参照）。

## ドキュメント

- `docs/ubuntu.md`: Ubuntu / WSL2 のセットアップとプラットフォーム別構成
- `docs/tools.md`: 導入ツールの基本的な使い方
- `docs/zsh.md`: zsh の構成（sheldon, fzf, 補完）
- `docs/nvim.md`: Neovim セットアップ

## メモ

- macOS のフォント（PlemolJP Console NF）は Homebrew cask で入ります。WSL2 側のフォントは `docs/ubuntu.md` を参照してください。
- home-manager 適用時、既存ファイルは `.before-nix` 拡張子でバックアップされます。
- `home.stateVersion` は `nix/home/common.nix` にあります。更新方針に合わせて調整してください。
- chezmoi は任意です（`chezmoi init --source "$PWD" --apply`）。`nix/` や `flake.nix` は `.chezmoiignore` で除外しています。
