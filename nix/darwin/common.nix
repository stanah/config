{ config, pkgs, lib, user, verticalMonitors ? [], ... }:
{
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nix.gc = {
    automatic = true;
    interval = { Weekday = 0; Hour = 3; Minute = 0; };
    options = "--delete-older-than 30d";
  };

  # Allow nix-darwin to know the user's home directory.
  users.users.${user}.home = "/Users/${user}";

  system.primaryUser = user;

  programs.zsh.enable = true;

  environment.systemPackages = with pkgs; [
    git
    gnupg
    ripgrep
    fd
  ];

  homebrew = {
    enable = true;
    onActivation = {
      cleanup = "none";
      autoUpdate = false;
      upgrade = false;
    };
    casks = [
      "font-plemol-jp-nf"
      "ghostty"
      "kiro-cli"
    ];
  };

  # Disable "Displays have separate Spaces" for better AeroSpace multi-monitor support
  system.defaults.spaces.spans-displays = true;

  # AeroSpace tiling window manager
  services.aerospace = {
    enable = true;
    settings = {
      # start-at-login is managed by nix-darwin's launchd service

      # Launch JankyBorders for focused window highlight
      after-startup-command = [
        "exec-and-forget ${pkgs.jankyborders}/bin/borders active_color=0xffe1e3e4 inactive_color=0xff494d64 width=5.0"
      ];

      # Hide border when only one window in workspace
      on-focus-changed = [
        "exec-and-forget ${pkgs.jankyborders}/bin/borders active_color=0xffe1e3e4 inactive_color=0xff494d64 width=5.0"
      ];

      # Normalizations
      enable-normalization-flatten-containers = true;
      enable-normalization-opposite-orientation-for-nested-containers = true;

      # Layout defaults
      default-root-container-layout = "tiles";
      default-root-container-orientation = "auto";
      accordion-padding = 30;

      # Gaps
      gaps = {
        inner.horizontal = 5;
        inner.vertical = 5;
        outer.left = 5;
        outer.bottom = 5;
        outer.top = 5;
        outer.right = 5;
      };

      # Main mode keybindings
      mode.main.binding = {
        # Focus: alt + i/j/k/l or arrows (crosses monitor boundaries)
        alt-j = "focus --boundaries all-monitors-outer-frame left";
        alt-k = "focus --boundaries all-monitors-outer-frame down";
        alt-i = "focus --boundaries all-monitors-outer-frame up";
        alt-l = "focus --boundaries all-monitors-outer-frame right";
        alt-left = "focus --boundaries all-monitors-outer-frame left";
        alt-down = "focus --boundaries all-monitors-outer-frame down";
        alt-up = "focus --boundaries all-monitors-outer-frame up";
        alt-right = "focus --boundaries all-monitors-outer-frame right";

        # Move windows: alt + shift + i/j/k/l or arrows
        alt-shift-j = "move left";
        alt-shift-k = "move down";
        alt-shift-i = "move up";
        alt-shift-l = "move right";
        alt-shift-left = "move left";
        alt-shift-down = "move down";
        alt-shift-up = "move up";
        alt-shift-right = "move right";

        # Join windows into container (for multi-column layouts)
        alt-shift-v = "join-with left";
        alt-shift-b = "join-with down";

        # Resize: alt + shift + minus/equal (smart), alt + ctrl + shift + arrows (directional)
        alt-shift-minus = "resize smart -50";
        alt-shift-equal = "resize smart +50";
        alt-ctrl-shift-left = "resize width -50";
        alt-ctrl-shift-down = "resize height +50";
        alt-ctrl-shift-up = "resize height -50";
        alt-ctrl-shift-right = "resize width +50";

        # Layout
        alt-slash = "layout tiles horizontal vertical";
        alt-comma = "layout accordion horizontal vertical";
        alt-f = "fullscreen";
        alt-shift-space = "layout floating tiling";

        # Move workspace to monitor: alt + ctrl + left/right
        alt-ctrl-left = "move-workspace-to-monitor prev";
        alt-ctrl-right = "move-workspace-to-monitor next";

        # Workspaces: alt + 1-9
        alt-1 = "workspace 1";
        alt-2 = "workspace 2";
        alt-3 = "workspace 3";
        alt-4 = "workspace 4";
        alt-5 = "workspace 5";
        alt-6 = "workspace 6";
        alt-7 = "workspace 7";
        alt-8 = "workspace 8";
        alt-9 = "workspace 9";

        # Move window to workspace: alt + shift + 1-9
        alt-shift-1 = "move-node-to-workspace 1";
        alt-shift-2 = "move-node-to-workspace 2";
        alt-shift-3 = "move-node-to-workspace 3";
        alt-shift-4 = "move-node-to-workspace 4";
        alt-shift-5 = "move-node-to-workspace 5";
        alt-shift-6 = "move-node-to-workspace 6";
        alt-shift-7 = "move-node-to-workspace 7";
        alt-shift-8 = "move-node-to-workspace 8";
        alt-shift-9 = "move-node-to-workspace 9";

        # Service mode
        alt-shift-semicolon = "mode service";
      };

      # Service mode (for less frequently used commands)
      mode.service.binding = {
        esc = "mode main";
        r = ["flatten-workspace-tree" "mode main"];
        f = ["layout floating tiling" "mode main"];
        backspace = ["close-all-windows-but-current" "mode main"];
      };
    } // lib.optionalAttrs (verticalMonitors != []) {
      # Assign workspaces 7-9 to vertical monitor (names from user-config.nix)
      workspace-to-monitor-force-assignment = {
        "7" = verticalMonitors;
        "8" = verticalMonitors;
        "9" = verticalMonitors;
      };
    };
  };

  home-manager.backupFileExtension = "before-nix";

  # nix-darwin uses a numeric stateVersion. Avoid changing this once set.
  system.stateVersion = 5;
}
