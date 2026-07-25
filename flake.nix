{
  description = "Workstations, home-manager environments, and devShells of Jaxxen";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    ccvm = {
      url = "github:openccvm/ccvm";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        claude-code.follows = "claude-code";
      };
    };
    claude-code = {
      url = "github:ryoppippi/nix-claude-code";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    impermanence = {
      url = "github:nix-community/impermanence";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    lanzaboote = {
      url = "github:nix-community/lanzaboote/v1.1.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixvim.url = "github:nix-community/nixvim";
    rehomify.url = "github:Ryokune/rehomify";
    rycee-addons = {
      url = "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = inputs @ {
    nixpkgs,
    ccvm,
    claude-code,
    disko,
    home-manager,
    impermanence,
    lanzaboote,
    nixvim,
    rehomify,
    sops-nix,
    ...
  }:
  let
    system = "x86_64-linux";
    pkgs = import nixpkgs {
      inherit system;
      overlays = [ claude-code.overlays.default ];
    };
    inherit (nixpkgs) lib;
  in {
    nixosConfigurations.iridium = lib.nixosSystem {
      inherit system;
      modules = [
        disko.nixosModules.disko
        impermanence.nixosModules.impermanence
        lanzaboote.nixosModules.lanzaboote
        rehomify.nixosModules.rehomify
        sops-nix.nixosModules.sops
        ./iridium/configuration.nix
        ./iridium/disks.nix
        ./iridium/hardware-configuration.nix
      ];
    };
    homeConfigurations = {
      jaxxen = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        extraSpecialArgs.addons = inputs.rycee-addons.packages.${system};
        modules = [
          ccvm.homeModules.ccvm
          nixvim.homeModules.nixvim
          ./jaxxen/home.nix
        ];
      };
    };
    devShells.${system}.default = import ./shell.nix {
      inherit pkgs;
      nixvim = nixvim.legacyPackages.${system}.makeNixvimWithModule {
        module = { ... }: {
          imports = [ ./jaxxen/nixvim.nix ];
        };
      };
    };
    formatter.${system} = pkgs.nixfmt;
  };
}
