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

  outputs = inputs@{ self, nixpkgs, darwin, home-manager, "user-config": userConfigInput, ... }:
    let
      userConfig = import userConfigInput;
      user = userConfig.user;
      host = userConfig.host;
      system = userConfig.system;
      pkgs = import nixpkgs { inherit system; };
      hostProfiles = {
        personal = {
          darwin = [ ./nix/darwin/personal.nix ];
          home = [ ./nix/home/personal.nix ];
        };
        work = {
          darwin = [ ./nix/darwin/work.nix ];
          home = [ ./nix/home/work.nix ];
        };
      };
      selectedProfile =
        if builtins.hasAttr host hostProfiles
        then hostProfiles.${host}
        else throw "Unknown host: ${host}. Add it to hostProfiles.";
    in
    {
      darwinConfigurations.${host} = darwin.lib.darwinSystem {
        inherit system;
        specialArgs = {
          inherit inputs user;
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
