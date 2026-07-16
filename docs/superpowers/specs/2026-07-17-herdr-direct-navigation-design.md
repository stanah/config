# Herdr 直接ナビゲーション設計

## 目的

Herdr の workspace と pane を、既存の tmux・Ghostty・AeroSpace と同じ `i/j/k/l` 配置で、prefix を押さずに移動できるようにする。

## キー割り当て

### Pane

| 操作 | 主ショートカット | 矢印互換 |
| --- | --- | --- |
| 上へ移動 | `Cmd+i` | `Cmd+Up` |
| 左へ移動 | `Cmd+j` | `Cmd+Left` |
| 下へ移動 | `Cmd+k` | `Cmd+Down` |
| 右へ移動 | `Cmd+l` | `Cmd+Right` |

### Workspace

| 操作 | 主ショートカット | 矢印互換 |
| --- | --- | --- |
| 前の workspace | `Cmd+Shift+j` | `Cmd+Shift+Left` |
| 次の workspace | `Cmd+Shift+l` | `Cmd+Shift+Right` |

## 設定方針

- ナビゲーション操作には Herdr の prefix を使用しない。
- Herdr の `keys.prefix` は変更せず、ナビゲーション以外の既定操作用に残す。
- `config/herdr/config.toml` の各アクションへ直接ショートカットを設定する。
- Ghostty が現在 tmux 専用に送信している `Cmd+i/j/k/l` と `Cmd+Shift+j/l` の CSI シーケンスを、Herdr も解釈できる CSI-u 形式へ統一する。
- `nix/home/common.nix` の tmux `user-keys` も同じ CSI-u シーケンスへ更新し、tmux の既存操作を維持する。
- 既存の `Cmd+矢印` と `Cmd+Shift+矢印` は互換ショートカットとして維持する。

## 検証

1. Home Manager の設定評価が成功することを確認する。
2. tmux で `Cmd+i/j/k/l` と矢印による pane 移動を確認する。
3. tmux で `Cmd+Shift+j/l` と矢印による window 移動を確認する。
4. Herdr の設定を再読み込みし、直接ショートカットによる pane と workspace の移動を確認する。
5. 入力が端に達した場合に、意図しない循環移動が発生しないことを確認する。

## 対象外

- Herdr の prefix を廃止すること。
- pane や workspace の作成・削除・サイズ変更ショートカットを変更すること。
- tmux の window と Herdr の tab の操作体系全体を再設計すること。
