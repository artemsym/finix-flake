# home-manager, via finix-community/community-modules.
#
# NOTE: finix has no systemd user session, so home-manager *user services* do
# not work here -- only home.packages, home.file and program configs. What
# gothness ran as systemd.user.services (caelestia shell, wallpaper engine,
# idle-lock) is started from niri's `spawn-at-startup` at the bottom instead.
# caelestia-shell itself isn't wired in below yet -- see caelestia.nix.
{ ... }:
{
  # A module function (not a plain attrset) so `lib` here resolves through
  # home-manager's own submodule specialArgs -- that's the extended lib
  # with `.hm.dag.*`, needed below. The outer NixOS-level `lib` doesn't
  # have that namespace.
  home-manager.users.goth = { pkgs, lib, ... }: {
    home.username = "goth";
    home.homeDirectory = "/home/goth";
    home.stateVersion = "26.05";

    # gtk.enable below mirrors the icon theme into dconf. There's no dbus/
    # dconf session available when finit runs hm-activate at boot (no
    # systemd user session on finix), so that step fails and aborts the
    # *whole* activation script before it reaches the xdg.configFile
    # symlinks (config.kdl among them) -- config.kdl silently stays a
    # missing/stale file after every boot. GTK3/4 icon settings still land
    # via ~/.config/gtk-{3,4}.0/settings.ini independent of dconf, so
    # skipping this step costs nothing on finix.
    home.activation.dconfSettings = lib.mkForce (lib.hm.dag.entryAnywhere "");

    # niri config: the gothness one verbatim (see ./dotfiles/niri-config.kdl),
    # plus the startup entries that replace the systemd user services.
    xdg.configFile."niri/config.kdl".text =
      builtins.readFile ./dotfiles/niri-config.kdl
      + ''

        // ---------- added for finix (no systemd user session) ----------
        // wallpaper engine: was systemd.user.services.wallpaper
        spawn-at-startup "linux-wallpaperengine" "--fps" "30" "--screen-root" "HDMI-A-1" "--screen-root" "DP-1" "2876210462"

        // idle auto-lock: was systemd.user.services.idle. Currently calls
        // out to caelestia-shell's lock IPC, which isn't wired up yet (see
        // caelestia.nix) -- swap for `swaylock` once that's sorted, or now
        // if you'd rather have a working lock screen today:
        //   spawn-at-startup "swayidle" "-w" "timeout" "300" "swaylock" "before-sleep" "swaylock"
        spawn-at-startup "swayidle" "-w" "timeout" "300" "caelestia-shell ipc call lock lock" "before-sleep" "caelestia-shell ipc call lock lock"
      '';

    programs.foot = {
      enable = true;
      settings = {
        main = {
          font = "JetBrainsMono Nerd Font:size=12";
          pad = "8x8";
        };
        "colors-dark" = {
          alpha = "0.5";
          background = "2d3a5c";
          foreground = "cfe4ff";
          regular0 = "0a0e1a"; regular1 = "e88388"; regular2 = "a8cc8c";
          regular3 = "dbab79"; regular4 = "71bef2"; regular5 = "d290e4";
          regular6 = "66c2cd"; regular7 = "cfe4ff";
          bright0 = "475266"; bright1 = "f09a97"; bright2 = "b6d7a8";
          bright3 = "f0c896"; bright4 = "9ad0ff"; bright5 = "e3a8f0";
          bright6 = "8fd4de"; bright7 = "ffffff";
        };
        key-bindings = {
          clipboard-copy = "Control+c";
          clipboard-paste = "Control+v";
        };
        cursor = { style = "beam"; blink = "yes"; };
      };
    };

    programs.starship = {
      enable = true;
      settings = {
        format = "$username$hostname$directory$git_branch$git_status$nix_shell$cmd_duration\n$character";
        username = {
          style_user = "bold green";
          style_root = "bold red";
          format = "[$user]($style)";
          show_always = true;
        };
        hostname = { format = "[@$hostname]($style):"; style = "bold green"; };
        directory = { style = "blue"; format = "[$path]($style) "; truncation_length = 3; };
        git_branch = { symbol = "🌱 "; format = "[$symbol$branch]($style) "; };
        nix_shell = { symbol = "❄️ "; format = "[$symbol$state]($style) "; disabled = false; };
        cmd_duration = { min_time = 500; format = "took [$duration]($style) "; };
        character = { success_symbol = "[❯](bold green)"; error_symbol = "[❯](bold red)"; };
      };
    };

    programs.git = {
      enable = true;
      settings.user.name = "artemsym";
      settings.user.email = "artemsym@users.noreply.github.com";
    };

    # Fixes blank/checkerboard icons -- nothing was telling GTK/Qt apps which
    # icon theme to use.
    gtk = {
      enable = true;
      iconTheme = {
        name = "Papirus-Dark";
        package = pkgs.papirus-icon-theme;
      };
    };

    # Qt apps don't read GTK icon settings on their own.
    qt = {
      enable = true;
      platformTheme.name = "gtk3";
    };
  };
}
