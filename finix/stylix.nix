# Stylix, wired in through home-manager only -- deliberately not the NixOS
# module.
#
# stylix.nixosModules.stylix reaches into a lot of options finix simply
# doesn't define (the services.xserver tree, the display-manager tree,
# console theming), and finix's evalModules fails hard on the first
# missing one rather than skipping it. The home-manager module imports
# nothing outside stylix's own hm/ and common/ trees, so it drops in
# unchanged -- and it's the half that themes everything actually visible
# on this machine: foot, GTK apps, the cursor, the icon theme.
#
# What stylix does NOT cover here: niri itself has no stylix target
# upstream, so the colours in dotfiles/niri-config.kdl stay hand-set.
#
# The values below are gothness's stylix.nix verbatim. That file was dead
# code over there -- never listed in configuration.nix's imports, and
# stylix was never a flake input -- so this is the first time these
# settings actually do anything.
{ inputs, pkgs, ... }:
{
  home-manager.users.goth = {
    imports = [ inputs.stylix.homeModules.stylix ];

    stylix.enable = true;
    stylix.polarity = "dark";
    stylix.opacity.terminal = 0.65;

    # stylix needs either a wallpaper to sample colours from or an explicit
    # scheme. linux-wallpaperengine paints an animated wallpaper here (see
    # home.nix), so there's no still image to sample -- the scheme is
    # spelled out instead.
    stylix.base16Scheme = {
      base00 = "0d1117";
      base01 = "161b22";
      base02 = "21262d";
      base03 = "3d4451";
      base04 = "6e7b8b";
      base05 = "c9d1d9";
      base06 = "dbe6f2";
      base07 = "ffffff";
      base08 = "e88388";
      base09 = "dbab79";
      base0A = "d290e4";
      base0B = "a8cc8c";
      base0C = "66c2cd";
      base0D = "1f6feb";
      base0E = "7fc8ff";
      base0F = "71bef2";
    };

    stylix.fonts = {
      monospace = {
        package = pkgs.nerd-fonts.jetbrains-mono;
        name = "JetBrainsMono Nerd Font";
      };
      sansSerif = {
        package = pkgs.noto-fonts;
        name = "Noto Sans";
      };
    };

    stylix.cursor = {
      package = pkgs.bibata-cursors;
      name = "Bibata-Modern-Ice";
      size = 24;
    };

    # Papirus, with stylix picking the dark variant from polarity above.
    # This replaces the hand-set `gtk.iconTheme` that used to live in
    # home.nix: stylix's icon module writes that exact option, and two
    # definitions of it would collide.
    stylix.icons = {
      enable = true;
      package = pkgs.papirus-icon-theme;
      dark = "Papirus-Dark";
      light = "Papirus-Light";
    };

    # Stylix's overlay path only themes gtksourceview and nixos-icons,
    # neither of which is used here, and it works by appending to
    # `nixpkgs.overlays`. community-modules hands home-manager a prebuilt
    # `pkgs` (the one from flake.nix, where config.allowUnfree is set for
    # the nvidia driver) rather than letting it instantiate its own, so
    # nudging nixpkgs.* from inside home-manager is a good way to end up
    # with a second, unfree-less nixpkgs. Left off entirely.
    stylix.overlays.enable = false;

    # stylix master vs whatever home-manager revision nixpkgs-unstable
    # happens to be carrying this week: they rarely match exactly, and the
    # mismatch warning would fire on every single rebuild.
    stylix.enableReleaseChecks = false;
  };
}
