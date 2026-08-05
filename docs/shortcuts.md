# shortcuts.json 構想メモ

## 概要

`shortcuts.json` をキーボードショートカットの Single Source of Truth として管理する。

- **表示**: `stanah/keymap-overlay` アプリが読み込んでオーバーレイ表示
- **同期**: 将来的に各ツールの設定ファイル（Ghostty, Zellij, AeroSpace, Neovim等）へ書き出す仕組みを検討

## 現状のショートカット管理状況

| レイヤー | ツール | 修飾キー | 設定ファイル |
|---------|--------|---------|-------------|
| ウィンドウ管理 | AeroSpace | Alt+key | `nix/darwin/common.nix` |
| ターミナル | Ghostty | Cmd+key | `config/ghostty/config` |
| ターミナルマルチプレクサ | Zellij | Ctrl+key | `config/zellij/config.kdl` |
| エディタ | Neovim | Space+key | `config/nvim/lua/config/keymaps.lua` |
| シェル | zsh/fzf | Ctrl+R 等 | - |

## shortcuts.json フォーマット案

```json
{
  "settings": {
    "triggerModifiers": ["command"],
    "holdThresholdMs": 500,
    "keymapPdfPath": "~/keymap.pdf",
    "keymapPdfShortcut": "command+shift+k"
  },
  "os": [
    {
      "category": "システム",
      "shortcuts": [
        { "keys": "command+space", "description": "Spotlight" },
        { "keys": "control+up", "description": "Mission Control" },
        { "keys": "fn+fn", "description": "音声入力", "type": "double_tap" }
      ]
    }
  ],
  "global": [
    {
      "category": "スクリーンショット",
      "shortcuts": [
        { "keys": "command+shift+3", "description": "全画面スクリーンショット" },
        { "keys": "command+shift+4", "description": "範囲選択スクリーンショット" }
      ]
    }
  ],
  "apps": {
    "com.microsoft.VSCode": {
      "name": "VS Code",
      "categories": [
        {
          "category": "ファイル",
          "shortcuts": [
            { "keys": "command+s", "description": "保存" },
            { "keys": ["command+k", "command+s"], "description": "すべて保存", "type": "sequence" }
          ]
        }
      ]
    },
    "com.mitchellh.ghostty": {
      "name": "Ghostty",
      "categories": [
        {
          "category": "ペイン操作",
          "shortcuts": [
            { "keys": "command+d", "description": "ペイン分割（横）" },
            { "keys": "command+shift+d", "description": "ペイン分割（縦）" }
          ]
        }
      ]
    }
  }
}
```

## TODO

- [ ] 既存の各設定ファイルからショートカットを抽出して shortcuts.json を作成
- [ ] shortcuts.json から各設定ファイルへの同期スクリプトを検討
