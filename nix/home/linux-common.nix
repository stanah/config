{ config, pkgs, lib, ... }:
{
  # Linux 共通設定。現状は ubuntu / gpu-server の両プロファイルとも WSL2 上の
  # Ubuntu を想定している（ネイティブ Linux が増えたらここを分割する）。
  #
  # WSL 前提のため、ここに入れないもの:
  #   - ターミナル (Ghostty) / フォント: Windows 側で管理する
  #   - GUI クリップボードツール: clip.exe (WSL interop) と OSC52 で足りる
  #
  # OS 側セットアップ (systemd, locale-gen, docker-ce, ログインシェル等) は
  # docs/ubuntu.md を参照。

  # 非 NixOS では glibc のロケールアーカイブが Nix ビルドのツールから見えず、
  # ロケール警告や日本語の文字化けが起きるため明示する
  home.sessionVariables = {
    LOCALE_ARCHIVE = "${pkgs.glibcLocales}/lib/locale/locale-archive";
  };

  home.packages = with pkgs; [
    # Server utilities
    httpie
  ];

  # Docker について:
  #   docker CLI / docker-compose は common.nix で Nix から入る（クライアントのみ）。
  #   デーモン (dockerd) は WSL 内の apt の docker-ce（systemd 有効化が前提）
  #   または Docker Desktop の WSL integration を使う。docs/ubuntu.md を参照。
}
