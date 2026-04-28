{
  description = "NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url   = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, ... } @ inputs:
    let
      secrets = import ./nixsec/secrets.nix;

      sharedArgs = {
        inherit inputs secrets;
      };

      mkHost = { system }: nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = sharedArgs // { hostname = secrets.hostname; };
        modules = [
          ./nixsec/hardware-configuration.nix
          ./hosts/hosts.nix
          ./hosts/${secrets.gpu}.nix
          inputs.home-manager.nixosModules.home-manager {
            home-manager.useGlobalPkgs   = true;
            home-manager.useUserPackages = true;
            home-manager.users.${secrets.username} = import ./home/home.nix;
            home-manager.extraSpecialArgs = sharedArgs;
          }
        ];
      };
    in
    {
      nixosConfigurations = {
        "${secrets.hostname}" = mkHost { system = "x86_64-linux"; };
        default               = mkHost { system = "x86_64-linux"; };
      };

      devShells.x86_64-linux =
        let pkgs = nixpkgs.legacyPackages.x86_64-linux;
        in {
          go      = import ./devshells/go.nix   { inherit pkgs; };
          rust    = import ./devshells/rust.nix  { inherit pkgs; };
          default = import ./devshells/go.nix   { inherit pkgs; };
        };
    };
}
