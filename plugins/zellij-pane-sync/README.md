# Zellij Pane Sync Plugin

Zellijで上下ペインの連動切り替えを実現するプラグイン。

## 機能

下段のペインにフォーカスすると、対応する上段のスタックペインが自動的に切り替わります。

```
┌─────────┬─────────┬─────────┬─────────┐
│ lazygit │  shell  │  yazi   │  ...    │  ← 上段（スタック、自動切替）
├─────────┼─────────┼─────────┼─────────┤
│ claude1 │ claude2 │ claude3 │ claude4 │  ← 下段（フォーカス）
└─────────┴─────────┴─────────┴─────────┘
```

## ビルド

```bash
# Rust と wasm32 ターゲットが必要
rustup target add wasm32-wasip1

# ビルドとインストール
./build.sh
```

## 使い方

```bash
# synced-workspace レイアウトで起動
zellij --layout synced-workspace
```

## 設定

プラグインは以下のパラメータを受け付けます:

| パラメータ | デフォルト | 説明 |
|-----------|-----------|------|
| `columns` | `4` | レイアウトの列数 |
| `debug` | `false` | デバッグ出力を有効化 |

レイアウトファイルでの設定例:

```kdl
pane {
    plugin location="file:~/.config/zellij/plugins/zellij-pane-sync.wasm" {
        columns "4"
        debug "false"
    }
}
```

## 動作原理

1. プラグインは `PaneUpdate` イベントを監視
2. 下段ペインがフォーカスされると、その列に対応する上段ペインを特定
3. 上段ペインを一時的にフォーカスしてスタックの前面に表示
4. 即座に下段ペインにフォーカスを戻す

## 要件

- Zellij 0.40.0 以上
- Rust 1.70 以上（ビルド時）
