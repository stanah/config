# Neovim setup (AstroNvim v5)

AstroNvim v5 をベースにした Neovim 設定です。

## Default editor

- `EDITOR` / `VISUAL` は `nvim` に設定しています。
- `vi` / `vim` / `vimdiff` は Neovim に置き換えられます。

## AstroNvim

- AstroNvim v5 を lazy.nvim 経由でプラグインとして読み込みます。
- AstroCommunity の Language Pack で言語サポートを追加しています。

## Language Packs (AstroCommunity)

- `pack.lua`
- `pack.typescript`
- `pack.rust`
- `pack.python`

各パックには LSP、フォーマッタ、リンタ、Treesitter パーサーが含まれます。
初回起動時に Mason が自動インストールします。

## Keymaps

AstroNvim デフォルトのキーマップを使用しています。
`<Space>` がリーダーキーです。主なバインド:

- `<Leader>e`: ファイルエクスプローラ (Neo-tree)
- `<Leader>f`: 検索メニュー (Telescope)
- `<Leader>ff`: ファイル検索
- `<Leader>fw`: 全文検索
- `<Leader>fb`: バッファ一覧
- `<Leader>g`: Git メニュー
- `<Leader>l`: LSP メニュー
- `<Leader>t`: ターミナル

詳細: https://docs.astronvim.com/mappings

## First run

初回は以下を確認してください:

- `:Lazy` でプラグインの状態を確認
- `:Mason` で LSP サーバーのインストール状態を確認
