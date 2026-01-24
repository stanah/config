{ config, pkgs, lib, ... }:
{
  # GPU Server specific configuration for Ubuntu with RTX 3080
  # Main use: LLM inference (Ollama, LM Studio), TTS Server, ComfyUI via Docker

  programs.zsh.shellAliases = {
    # GPU monitoring
    nv = "nvidia-smi";
    nvw = "watch -n 1 nvidia-smi";
  };

  home.packages = with pkgs; [
    # Server utilities
    httpie

    # Note: nvtop is installed via apt to avoid heavy CUDA build in Nix
    # sudo apt install nvtop
  ];
}
