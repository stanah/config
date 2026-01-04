# config

chezmoi + nix-darwin + home-manager をまとめたリポジトリです。

## 使い方 (macOS)

### 1) Nix を入れる
公式インストーラで導入します（詳細は Nix のドキュメントを参照）。

### 2) nix-darwin を初回適用
以下で nix-darwin をブートストラップします。

```sh
sudo nix run github:LnL7/nix-darwin -- switch --flake ".#personal"
```

別ユーザ/ホストで使う場合は `user-config` を差し替えられます。

```sh
sudo nix run github:LnL7/nix-darwin -- switch --flake ".#myhost" \
  --override-input user-config path:/path/to/user-config.nix
```

または、`scripts/bootstrap.sh`を実行します（引数が無い場合は `nix/user-config.nix` の `host` を参照）：

```sh
sudo ./scripts/bootstrap.sh
```

### 3) chezmoi を初期化して反映（任意）
このリポジトリは Nix/HM で設定を管理します。chezmoi を使う場合のみ実行します。

```sh
nix profile install nixpkgs#chezmoi
chezmoi init --source "$PWD" --apply
```

## 変更ポイント

- `nix/user-config.nix` の `user`, `host`, `system` を自分の環境に合わせて変更してください。
- `networking.hostName` は設定していないので、既存の macOS ホスト名が維持されます。
- `nix/darwin/personal.nix` の Homebrew パッケージを好みに合わせて編集してください。
- `nix/home/common.nix` の `home.stateVersion` は更新方針に合わせて調整してください。
- 秘密情報は `~/.config/private/env` と `~/.config/private/gitconfig` に置き、Git には載せません。
- 既存ファイルは `.before-nix` でバックアップされます。

## 追加の分割

- `nix/darwin/common.nix` と `nix/darwin/personal.nix` に分割しています。
- `nix/home/common.nix` と `nix/home/personal.nix` に分割しています。

## ドキュメント

- `docs/zsh.md` (zsh 移行/補完/キーバインド)
- `docs/tools.md` (導入ツールの基本的な使い方)
- `docs/nvim.md` (Neovim セットアップ)

## プライベート環境変数のセットアップ

秘密情報（APIキーなど）は Git 管理外の `~/.config/private/env` に置きます。

```sh
mkdir -p ~/.config/private
cp config/private.env.example ~/.config/private/env
# 実際の値を設定
vim ~/.config/private/env
```

このファイルは zsh 起動時に自動で読み込まれます。

## 管理される設定

- `config/ghostty/config`
- `config/htop/htoprc`
- `config/nvim/`
- `config/mise-global/config.toml`
- `config/starship/starship.toml`

## フォント

- `font-plemol-jp-nf` は Homebrew cask でインストールされます。

## メモ

- chezmoi の source はリポジトリ直下です。`nix/` や `flake.nix` は `.chezmoiignore` で除外しています。
- darwin の適用は `sudo darwin-rebuild switch --flake '.#personal'` で実行できます。
- 既存設定をリポジトリへ反映する場合は `scripts/sync-config.sh` を実行してください。

## 設定の同期手順（実機 → リポジトリ）

実機で設定を変更した場合は、以下の手順でリポジトリへ反映します。

```sh
./scripts/sync-config.sh
git add config/ghostty/config config/htop/htoprc config/starship/starship.toml
git commit -m "設定更新"
```
