# Tools quickstart

このドキュメントは「何をするコマンドか」を短く説明します。

## ghq（リポジトリ管理）

- 指定リポジトリを `GHQ_ROOT`（既定: `~/work`）配下にクローンする  
  - `ghq get github.com/OWNER/REPO`
- 取得済みリポジトリを一覧表示する  
  - `ghq list`

## git private config（個人情報の分離）

Git の個人情報やトークンは **リポジトリに含めず**にここへ置きます。

`~/.config/private/gitconfig`

例:

```
[user]
    name = your-name
    email = you@example.com
[coderabbit]
    machineId = your-machine-id
```

## zoxide（高速ディレクトリ移動）

- 以前移動した履歴からディレクトリにジャンプ  
  - `z <keyword>`

## mise（言語/ツールのバージョン管理）

- グローバルに使うバージョンを固定する  
  - `mise use -g node@20`
  - `mise use -g python@3.12`
- 現在有効なツール一覧を表示する  
  - `mise ls`

このリポジトリは `~/.config/mise/config.toml` を配布します  
（元ファイル: `config/mise-global/config.toml`）。  
適用時に `mise install --yes` を実行するので、**Node などは自動で入ります**。  
また、適用時に `mise trust` も実行されます。

### Foundry

Foundry は mise で固定されています:

- `foundry = "1.5.1"`

### pnpm（デフォルト化）

pnpm は mise でインストールされ、以下は **pnpm に置き換え**られます:

- `pnpm = "latest"`
- `npm`, `yarn`, `yarnpkg` → `pnpm`

## claude-code / cursor cli

この2つは公式のインストールスクリプトを使って自動インストールします。
初回は `darwin-rebuild switch` 時に実行されます。

- `claude`（claude-code CLI）
- `cursor-agent`（Cursor CLI）

## CodeRabbit CLI

CodeRabbit CLI は公式スクリプトで自動インストールします。
必要に応じてログインや初期設定を行ってください。

- `coderabbit`

## direnv（ディレクトリごとの環境変数）

- `.envrc` を許可して環境変数を読み込む  
  - `direnv allow`

## atuin（履歴検索）

- コマンド履歴を検索する  
  - `atuin search <query>`

## lazygit（Git TUI）

- Git 用の操作画面を起動する  
  - `lazygit`

## yazi（ファイルマネージャ）

- TUI ファイルマネージャを起動する  
  - `yazi`

## eza / bat / dust / tldr（CLI 置き換え）

- `eza -la --icons --git`  
  - `ls` の高機能版（アイコン/ Git 状態表示）
- `bat <file>`  
  - `cat` の高機能版（シンタックスハイライト付き）
- `dust <dir>`  
  - `du` の見やすい版（サイズを分かりやすく表示）
- `tldr <command>`  
  - コマンドの短い使用例を表示
