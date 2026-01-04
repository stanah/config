# Neovim setup

Vim を Neovim に置き換え、lazy.nvim でプラグインを管理します。

## Default editor

- `EDITOR` / `VISUAL` は `nvim` に設定しています。
- `vi` / `vim` / `vimdiff` は Neovim に置き換えられます。

## Plugins (basic set)

- lazy.nvim  
  - プラグインマネージャ。遅延ロードで起動を軽くします。
- oil.nvim  
  - バッファ内でファイル操作ができるファイラー。
- telescope.nvim  
  - ファイル/文字列検索の統合UI（`find_files`, `live_grep` など）。
- nvim-treesitter  
  - 構文解析によりハイライトやインデントを安定化。
- mason.nvim + mason-lspconfig + nvim-lspconfig  
  - LSP サーバのインストールと設定を補助。
- nvim-cmp + LuaSnip  
  - 補完とスニペットの統合UI。
- gitsigns.nvim  
  - 行ごとの差分をガターに表示。

## LSP servers

次の言語向けに有効化しています:

- TypeScript
- Rust
- Python
- Solidity

初回起動時に Mason がインストールします。  
`pyright` / `ts_ls` / Solidity LSP は npm を使うため Node が必要です。  
Node は mise により自動で入ります。

## Keymaps

- `<leader>o`: Oil（ファイラーを開く）
- `<leader>g`: lazygit（ターミナルで開く）
- `<leader>ff`: ファイル検索
- `<leader>fg`: 全文検索（ripgrep）
- `<leader>fb`: バッファ一覧
- `<leader>fh`: ヘルプ検索
- `[d` / `]d`: 診断の前後移動

## First run

初回は以下を確認してください:

- `:Lazy` to confirm plugins
- `:Mason` to check LSP installs
