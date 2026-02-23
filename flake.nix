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
          darwin = [ ./nix/darwin/personal.nix ];
          home = [ ./nix/home/personal.nix ];
        };
        work = {
          darwin = [ ./nix/darwin/work.nix ];
          home = [ ./nix/home/work.nix ];
        };
        # Linux profiles
        gpu-server = {
          darwin = [];
          home = [ ./nix/home/gpu-server.nix ];
        };
      };
      selectedProfile =
        if builtins.hasAttr host hostProfiles
        then hostProfiles.${host}
        else throw "Unknown host: ${host}. Add it to hostProfiles.";
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
