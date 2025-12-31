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
