# Ubuntu (WSL2) セットアップ

このリポジトリの Linux プロファイルは、いずれも WSL2 上の Ubuntu を想定している。

- **ubuntu**：GPU を持たない通常の WSL2 Ubuntu。
- **gpu-server**：NVIDIA GPU を持つ WSL2 Ubuntu（例: RTX 3080）。
  主用途は LLM 推論 (Ollama, LM Studio)、TTS Server、Docker 経由の ComfyUI。

ターミナル、フォント、クリップボードの描画は Windows 側の責務なので、WSL 内には入れない。
PlemolJP Console NF などのフォントは Windows Terminal 側にインストールする。

## プラットフォーム別の構成

Home Manager モジュールは次のように分割している。

| モジュール | 役割 | 読み込むプロファイル |
|---|---|---|
| `nix/home/common.nix` | 全 OS 共通（zsh, tmux, CLI ツール, docker CLI） | すべて |
| `nix/home/darwin.nix` | macOS 共通（colima, brew shellenv） | personal, work |
| `nix/home/personal.nix` / `work.nix` | 個人 Mac / 業務 Mac 固有 | 各プロファイル |
| `nix/home/linux-common.nix` | WSL2 Ubuntu 共通（LOCALE_ARCHIVE, httpie） | ubuntu, gpu-server |
| `nix/home/ubuntu.nix` | 通常 Ubuntu 固有（現状は空） | ubuntu |
| `nix/home/gpu-server.nix` | GPU マシン固有（nvidia-smi エイリアス） | gpu-server |

`nix/darwin/` 以下（AeroSpace, JankyBorders, Homebrew casks）は macOS 専用で、Linux プロファイルからは読み込まれない。

インストールされるものの分類は次のとおり。

| 分類 | 内容 |
|---|---|
| 全 OS 共通 | zsh, starship, tmux, Neovim, mise（node, pnpm, bun, uv, herdr, hunkdiff 等）, git, gh, lazygit, fzf, eza, bat, ripgrep 系ツール, atuin, direnv, zellij, btop, htop, docker CLI, docker-compose, lazydocker |
| macOS のみ | colima（Docker デーモン）, AeroSpace, JankyBorders, Homebrew casks（Ghostty, フォント） |
| WSL2 Ubuntu 共通 | LOCALE_ARCHIVE（glibc ロケール）, httpie |
| GPU マシンのみ | nvidia-smi エイリアス（nv, nvw） |

## OS 側セットアップ（Home Manager 管理外）

Home Manager が扱えない部分は、初回に手動で設定する。

### 1. systemd を有効にする

Nix デーモンと docker-ce の動作に必要になる。
`/etc/wsl.conf` に以下を書き、Windows 側で `wsl --shutdown` してから再起動する。

```ini
[boot]
systemd=true
```

### 2. ロケールを生成する

```bash
sudo locale-gen en_US.UTF-8
sudo update-locale
```

Nix ビルドのツール向けには、Home Manager が `LOCALE_ARCHIVE` を設定する（`nix/home/linux-common.nix`）。

### 3. zsh をログインシェルにする

zsh 本体は Home Manager が入れるが、ログインシェルの変更は OS 側の操作になる。

```bash
command -v zsh | sudo tee -a /etc/shells
chsh -s "$(command -v zsh)"
```

### 4. Nix をインストールして Home Manager を適用する

```bash
sh <(curl --fail -L https://nixos.org/nix/install) --daemon
```

`nix/user-config.nix` を作成し、`host` を `ubuntu` または `gpu-server`、`system` を `x86_64-linux` にする。
その後 `./scripts/bootstrap.sh` を実行すると、Linux では home-manager の適用まで行われる。
2回目以降の反映は `./scripts/hm-switch.sh` でよい。

### 5. Docker Engine を入れる

docker CLI と docker compose は Nix から入る（クライアントのみ）。
デーモンは WSL 内の docker-ce を使う（Docker Desktop の WSL integration でも動くが、apt の docker-ce の方が構成が単純になる）。

```bash
curl -fsSL https://get.docker.com | sudo sh
sudo usermod -aG docker "$USER"
```

`newgrp docker` するか再ログインすると、sudo なしで docker を使える。

### 6. GPU マシンのみ: NVIDIA 関連

WSL2 の GPU パススルーでは、NVIDIA ドライバは Windows 側にだけインストールする。
WSL 内に Linux 用ドライバを入れてはいけない（`/usr/lib/wsl/lib/` 経由で Windows 側ドライバの `nvidia-smi` が見える）。

GPU コンテナを動かす場合は、WSL 内に nvidia-container-toolkit だけを入れる。

```bash
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | \
  sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
  sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
  sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
sudo apt-get update && sudo apt-get install -y nvidia-container-toolkit
sudo nvidia-ctk runtime configure --runtime=docker
sudo systemctl restart docker
```

動作確認は次のコマンドで行う。

```bash
docker run --rm --gpus all nvidia/cuda:12.4.1-base-ubuntu22.04 nvidia-smi
```

ネイティブ（非コンテナ）で CUDA を使う場合のみ、WSL 用 CUDA Toolkit を別途入れる。
