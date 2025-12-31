# Neovim setup

This setup replaces Vim with Neovim and uses lazy.nvim for plugins.

## Default editor

- `EDITOR` / `VISUAL` are set to `nvim`.
- `vi`, `vim`, and `vimdiff` are aliased to Neovim.

## Plugins (basic set)

- lazy.nvim (plugin manager)
- oil.nvim (file explorer)
- telescope.nvim (finder)
- nvim-treesitter (syntax)
- mason.nvim + mason-lspconfig + nvim-lspconfig (LSP)
- nvim-cmp + LuaSnip (completion)
- gitsigns.nvim

## LSP servers

Configured for:

- TypeScript
- Rust
- Python
- Solidity

Mason is used to install them on first run.

## Keymaps

- `<leader>o`: Oil
- `<leader>ff`: Find files
- `<leader>fg`: Live grep
- `<leader>fb`: Buffers
- `<leader>fh`: Help
- `[d` / `]d`: Prev/Next diagnostic

## First run

Open Neovim and run:

- `:Lazy` to confirm plugins
- `:Mason` to check LSP installs
