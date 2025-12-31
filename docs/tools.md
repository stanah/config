# Tools quickstart

## ghq

- Clone into GHQ_ROOT (`~/work`):
  - `ghq get github.com/OWNER/REPO`
- List local repos:
  - `ghq list`

## git private config

Put personal settings here (not committed):

`~/.config/private/gitconfig`

Example:

```
[user]
    name = your-name
    email = you@example.com
[coderabbit]
    machineId = your-machine-id
```

## zoxide

- Jump to a directory by name:
  - `z <keyword>`

## mise (replaces nvm/pyenv)

- Set a tool version globally:
  - `mise use -g node@20`
  - `mise use -g python@3.12`
- Show current tools:
  - `mise ls`

This repo provides `~/.config/mise/config.toml` (from `config/mise-global/config.toml`)
and runs `mise install --yes` after activation, so Node is installed automatically.
The activation step also trusts the config file automatically.

Foundry is pinned via mise:

- `foundry = "1.5.1"`

pnpm is installed via mise and set as the default package manager:

- `pnpm = "latest"`
- `npm`, `yarn`, `yarnpkg` are aliased to `pnpm`

## direnv

- Allow a project env:
  - `direnv allow`

## atuin (no key binding by default)

- Search history:
  - `atuin search <query>`

## lazygit

- Launch UI:
  - `lazygit`

## yazi

- Launch file manager:
  - `yazi`

## eza / bat / dust / tldr

- `eza -la --icons --git`
- `bat <file>`
- `dust <dir>`
- `tldr <command>`
