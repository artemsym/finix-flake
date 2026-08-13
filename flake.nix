{
  description = "finix config ported from gothness";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    finix.url = "github:finix-community/finix";
    community-modules.url = "github:finix-community/community-modules";
    niri-caelestia-shell = {
      url = "github:jutraim/niri-caelestia-shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = inputs @ {
    self,
    nixpkgs,
    finix,
    community-modules,
    ...
  }: let
    pkgs = import nixpkgs {
      system = "x86_64-linux";
      config.allowUnfree = true;
    };
  in {
    nixosConfigurations.finixos = finix.lib.finixSystem {
      inherit (pkgs) lib;
      modules =
        (with finix.nixosModules; [
          {
            nixpkgs.pkgs = nixpkgs.lib.mkDefault pkgs;
          }
          (./finix/configuration.nix)
          nix-daemon
          openssh
          sysklogd
          limine
          sudo
          polkit
          getty
          bash
          networkmanager
          niri
          sddm
          pipewire
          wireplumber
          rtkit
          bluetooth
          avahi
          gamemode
          thermald
          earlyoom
          fstrim
          udisks2
          upower
          tuigreet
          xwayland-satellite
          zzz
        ])
        ++ (with community-modules.nixosModules; [
          home-manager
          nix-ld
          soteria
        ]);
      specialArgs = {
        inherit inputs;
        modulesPath = toString nixpkgs + "/nixos/modules";
      };
    };
  };
}
