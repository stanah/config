{
  user = "stanah";

  # Host profiles:
  #   macOS: "personal", "work"
  #   Linux (WSL2 Ubuntu): "ubuntu" (GPU なし), "gpu-server" (NVIDIA GPU あり)
  host = "personal";

  # System architectures:
  #   macOS: "aarch64-darwin" (Apple Silicon), "x86_64-darwin" (Intel)
  #   Linux: "x86_64-linux", "aarch64-linux"
  system = "aarch64-darwin";

  # AeroSpace: monitor names for vertical display (run: system_profiler SPDisplaysDataType)
  # verticalMonitors = [ "LG HDR QHD" "DELL P2421D" ];
  verticalMonitors = [];
}
