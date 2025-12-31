# Zsh setup

このリポジトリでは oh-my-zsh をやめて sheldon でプラグインを管理し、
fzf のデフォルトキーバインドを使う構成にしています。

## 移行の概要

- oh-my-zsh は使いません。見た目は starship で統一します。
- プラグインは sheldon で管理します（`~/.config/sheldon/plugins.toml`）。
- fzf のデフォルトキーバインドを使います（Ctrl-R / Alt-C / Ctrl-T）。
- peco 系のヘルパーは廃止しています。

## Key bindings (fzf default)

- Ctrl-R: コマンド履歴検索
- Alt-C: ディレクトリ移動
- Ctrl-T: ファイル選択

## Plugins (sheldon)

- fzf-tab  
  - TAB 補完を fzf で選択できる UI に置き換えます。
- fast-syntax-highlighting  
  - コマンドの色分け・ハイライトを高速に行います。
- zsh-autosuggestions  
  - 過去の入力履歴から予測入力を表示します。

## 補完の仕組み

- `zsh-completions` を fpath に追加してから `compinit` を実行しています。
- 補完の視認性を上げるため、`fzf-tab` と併用しています。

## Package manager aliases

- `npm`, `yarn`, `yarnpkg` は `pnpm` に置き換えています。

## CLIの配置場所

- `~/.local/bin` を PATH に追加しているため、ここに入るCLIが利用可能になります。

## Private env file

秘密情報は **Gitに載せず** ここに置きます。

- `~/.config/private/env`

このファイルが存在すれば zsh から読み込まれます。

## Optional app integrations

アプリ固有のシェル統合（例: Kiro CLI）は、
`nix/home/personal.nix` か `~/.config/private/env` に追加してください。
