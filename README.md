# config

chezmoi + nix-darwin + home-manager をまとめたリポジトリです。

## 使い方 (macOS)

### 1) Nix を入れる
公式インストーラで導入します（詳細は Nix のドキュメントを参照）。

### 2) nix-darwin を初回適用
以下で nix-darwin をブートストラップします。

```sh
nix run github:LnL7/nix-darwin -- switch --flake .#personal
```

### 3) chezmoi を初期化して反映
このリポジトリを chezmoi の source として使います。

```sh
nix profile install nixpkgs#chezmoi
chezmoi init --source "$PWD" --apply
```

## 変更ポイント

- `flake.nix` の `user`, `host`, `system` を自分の環境に合わせて変更してください。
- `networking.hostName` は設定していないので、既存の macOS ホスト名が維持されます。
- `nix/darwin/personal.nix` の Homebrew パッケージを好みに合わせて編集してください。
- `nix/home/common.nix` の `home.stateVersion` は更新方針に合わせて調整してください。

## 追加の分割

- `nix/darwin/common.nix` と `nix/darwin/personal.nix` に分割しています。
- `nix/home/common.nix` と `nix/home/personal.nix` に分割しています。

## メモ

- chezmoi の source はリポジトリ直下です。`nix/` や `flake.nix` は `.chezmoiignore` で除外しています。
- darwin の適用は `darwin-rebuild switch --flake .#personal` で実行できます。
