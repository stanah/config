{
  description = "chezmoi + nix-darwin + home-manager config";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    darwin.url = "github:LnL7/nix-darwin";
    darwin.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    user-config = {
      url = "path:./nix/user-config.nix";
      flake = false;
    };
  };

  outputs = inputs@{ self, nixpkgs, darwin, home-manager, ... }:
    let
      userConfig = import inputs."user-config";
      user = userConfig.user;
      host = userConfig.host;
      system = userConfig.system;
      verticalMonitors = userConfig.verticalMonitors or [];
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
      isDarwin = builtins.match ".*-darwin" system != null;
      hostProfiles = {
        # macOS profiles
        personal = {
          platform = "darwin";
          darwin = [ ./nix/darwin/personal.nix ];
          home = [ ./nix/home/darwin.nix ./nix/home/personal.nix ];
        };
        work = {
          platform = "darwin";
          darwin = [ ./nix/darwin/work.nix ];
          home = [ ./nix/home/darwin.nix ./nix/home/work.nix ];
        };
        # Linux profiles (いずれも WSL2 Ubuntu 想定)
        ubuntu = {
          platform = "linux";
          darwin = [];
          home = [ ./nix/home/linux-common.nix ./nix/home/ubuntu.nix ];
        };
        gpu-server = {
          platform = "linux";
          darwin = [];
          home = [ ./nix/home/linux-common.nix ./nix/home/gpu-server.nix ];
        };
      };
      selectedProfile =
        if !(builtins.hasAttr host hostProfiles)
        then throw "Unknown host: ${host}. Add it to hostProfiles."
        else if (hostProfiles.${host}.platform == "darwin") != isDarwin
        then throw "Host '${host}' is a ${hostProfiles.${host}.platform} profile but system is '${system}'. Fix nix/user-config.nix."
        else hostProfiles.${host};
    in
    {
      # Darwin configurations (macOS only)
      darwinConfigurations = if isDarwin then {
        ${host} = darwin.lib.darwinSystem {
          inherit system;
          specialArgs = {
            inherit inputs user verticalMonitors;
          };
          modules = [
            ./nix/darwin/common.nix
          ] ++ selectedProfile.darwin ++ [
            home-manager.darwinModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.extraSpecialArgs = { inherit inputs user; };
              home-manager.users.${user} = {
                imports = [ ./nix/home/common.nix ] ++ selectedProfile.home;
              };
            }
          ];
        };
      } else {};

      # Standalone home-manager configurations (for Linux or standalone macOS use)
      homeConfigurations.${user} = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        extraSpecialArgs = {
          inherit inputs user;
        };
        modules = [
          ./nix/home/common.nix
        ] ++ selectedProfile.home;
      };
    };
}
