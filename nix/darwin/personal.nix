{ ... }:
{
  homebrew = {
    enable = true;
    onActivation = {
      cleanup = "zap";
      autoUpdate = false;
      upgrade = false;
    };
    brews = [
      "git"
      "gh"
    ];
    casks = [
      "iterm2"
      "1password"
    ];
  };
}
