{ config, pkgs, lib, ... }:
{
  # GPU マシン固有の設定 (WSL2 Ubuntu + NVIDIA GPU, 例: RTX 3080)
  # 主用途: LLM 推論 (Ollama, LM Studio), TTS Server, ComfyUI via Docker
  # Linux 共通設定は linux-common.nix にある（flake.nix で両方読み込む）

  programs.zsh.shellAliases = {
    # GPU monitoring (WSL では nvidia-smi は Windows 側ドライバが
    # /usr/lib/wsl/lib/ 経由で提供する)
    nv = "nvidia-smi";
    nvw = "watch -n 1 nvidia-smi";
  };

  # WSL2 の GPU パススルーでは Linux 側に NVIDIA ドライバを入れてはいけない。
  # WSL 内に必要なのは GPU コンテナ用の nvidia-container-toolkit (apt) のみ。
  # 手順は docs/ubuntu.md を参照。
}
