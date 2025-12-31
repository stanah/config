# Zsh setup

This repo replaces oh-my-zsh with sheldon and keeps fzf default key bindings.

## Migration notes

- oh-my-zsh is removed. Theme is handled by starship.
- Plugins are managed by sheldon (`~/.config/sheldon/plugins.toml`).
- fzf default bindings are enabled (Ctrl-R, Alt-C, Ctrl-T).
- `peco`-based helpers are removed.

## Key bindings (fzf default)

- Ctrl-R: search command history
- Alt-C: change directory
- Ctrl-T: select files

## Plugins (sheldon)

- fzf-tab
- fast-syntax-highlighting
- zsh-autosuggestions

## Private env file

Secrets should NOT be committed. Put them here:

- `~/.config/private/env`

This file is sourced by zsh if it exists.

## Optional app integrations

If you need app-specific shell integration (e.g. Kiro CLI), add the snippet in
`nix/home/personal.nix` or `~/.config/private/env` instead of committing it.
