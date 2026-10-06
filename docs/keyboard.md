# macOS キーボード設定

macOS のキー配置は Karabiner-Elements と nix-darwin の system defaults で管理しています。

## 設定内容

| 物理キー | 単押し | 他のキーと組み合わせたとき |
|---|---|---|
| 左 Command（スペースの左隣） | 英数 | Control |
| 左 Control | - | Command |
| 右 Command | かな | Command |

- 左 Control と左 Command の入れ替えは、内蔵キーボードと外付けキーボードの両方に適用されます。
- F1〜F12 はメディアキー（明るさ・音量など）のままです。F キーとして使うときは fn を押しながら入力します（`com.apple.keyboard.fnState = false`）。
- fn（地球儀）キーの単押しの挙動は管理していません。

## 管理場所

| 対象 | ファイル |
|---|---|
| Karabiner-Elements 本体（Homebrew cask） | `nix/darwin/common.nix` |
| fn / F キーの挙動 | `nix/darwin/common.nix` |
| Karabiner のルール | `config/karabiner/karabiner.json` |
| `karabiner.json` の配置 | `nix/home/darwin.nix` |

Karabiner-Elements は `karabiner.json` を自分で書き換えます。
そのため Nix store への symlink ではなく、書き込み可能なコピーとして `~/.config/karabiner/karabiner.json` に配置します。
リポジトリの内容と異なる場合は、既存のファイルを `karabiner.json.before-nix` に退避してから上書きします。

Karabiner の GUI で変更した場合は、`./scripts/sync-config.sh` でリポジトリへ回収してからコミットします。
回収しないまま rebuild すると、GUI での変更はリポジトリの内容で上書きされます。

## 初回セットアップ

`sudo -H ./scripts/rebuild.sh` で Karabiner-Elements がインストールされた後、次の操作を手動で行います。
これらは macOS のセキュリティ上、Nix から自動化できません。

1. Karabiner-Elements を起動し、ドライバ（システム拡張）の許可を求められたら「システム設定 > 一般 > ログイン項目と機能拡張」で許可します。
2. 「システム設定 > プライバシーとセキュリティ > 入力監視」で Karabiner の項目を許可します（Karabiner-Elements の画面で案内されます）。
3. 「システム設定 > キーボード > キーボードショートカット > 修飾キー」が初期状態であることを確認します。ここで Control と Command を入れ替えていると、Karabiner と二重に入れ替わります。

## 注意

- Karabiner の仮想キーボードの種類は `ansi`（US 配列）にしています。JIS 配列の Mac では `config/karabiner/karabiner.json` の `keyboard_type_v2` を `jis` に変更してください。
- 左 Command（物理）を押してすぐ離すと、Control の押下は送らずに英数だけを送ります（`lazy`）。1 秒以上押し続けて離した場合は英数を送りません。
