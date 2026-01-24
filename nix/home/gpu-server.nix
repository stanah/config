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
    # GPU monitoring
    nvtopPackages.full

    # Server utilities
    httpie
  ];
}
