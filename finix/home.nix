# home-manager, via finix-community/community-modules.
#
# NOTE: finix has no systemd user session, so home-manager *user services* do
# not work here -- only home.packages, home.file and program configs. What
# gothness ran as systemd.user.services (caelestia shell, wallpaper engine,
# idle-lock) is started from niri's `spawn-at-startup` instead, below.
#
# Theming lives in stylix.nix, not here.
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

    # Anything that turns on home-manager's gtk module (stylix's gtk target
    # does, see stylix.nix) makes it mirror the theme into dconf during
    # activation. finit runs hm-activate at boot with no dbus session and
    # no dconf service -- there's no systemd user session on finix -- so
    # that step throws and aborts the *whole* activation script before it
    # reaches the xdg.configFile symlinks (config.kdl among them), leaving
    # config.kdl a missing or stale file after every boot. GTK3/4 still
    # read ~/.config/gtk-{3,4}.0/settings.ini, which is written
    # independently of dconf, so skipping this step costs nothing here.
    home.activation.dconfSettings = lib.mkForce (lib.hm.dag.entryAnywhere "");

    # niri config: the gothness one verbatim (see ./dotfiles/niri-config.kdl),
    # plus the startup entries that replace the systemd user services.
    #
    # force = true: niri auto-generates a default config.kdl on first launch
    # if none exists yet. That happened here before hm-activate ever got a
    # chance to run (or an earlier run failed before reaching this file, e.g.
    # the dconf bug fixed above), so a real file -- not a home-manager
    # symlink -- was already sitting at this path. Without `force`,
    # checkLinkTargets refuses to touch it and aborts activation entirely
    # (every file below silently never gets applied, not just this one).
    xdg.configFile."niri/config.kdl" = {
      force = true;
      text =
        builtins.readFile ./dotfiles/niri-config.kdl
        + ''

        // ---------- added for finix (no systemd user session) ----------
        // Everything below was a systemd user service on gothness.

        // the bar/launcher/dashboard: was upstream's caelestia home-manager
        // module, whose unit runs the binary with no arguments (see
        // caelestia.nix).
        spawn-at-startup "caelestia-shell"

        // wallpaper engine: was systemd.user.services.wallpaper
        spawn-at-startup "linux-wallpaperengine" "--fps" "30" "--screen-root" "HDMI-A-1" "--screen-root" "DP-1" "2481537915"

        // idle auto-lock: was systemd.user.services.idle. caelestia-shell's
        // own lock (modules/lock) only reacts to this IPC call -- there's no
        // separate lock binary to run. If caelestia is ever taken back out,
        // this needs to become:
        //   spawn-at-startup "swayidle" "-w" "timeout" "300" "swaylock" "before-sleep" "swaylock"
        spawn-at-startup "swayidle" "-w" "timeout" "300" "caelestia-shell ipc call lock lock" "before-sleep" "caelestia-shell ipc call lock lock"
      '';
    };

    # Font, colours and terminal opacity now come from stylix (stylix.nix).
    # Its foot target writes `settings.main.font` and the entire
    # `colors-dark` block itself, and those definitions are plain values,
    # not mkDefault -- setting them here too is a merge conflict, not an
    # override. Only what stylix has no opinion about is left.
    # Same insurance as config.kdl above: if anything ever leaves a real
    # foot.ini at this path, checkLinkTargets aborts the entire activation
    # rather than skipping the one file, and every other config here
    # silently stops updating too. Nothing here is hand-edited, so it's
    # always safe to overwrite.
    xdg.configFile."foot/foot.ini".force = true;

    programs.foot = {
      enable = true;
      settings = {
        main.pad = "8x8";
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

    # The built-in NixOS logo is the snowflake; fastfetch draws it from two
    # colour slots ($1/$2, normally the two blues), so recolouring is just
    # reassigning those two rather than shipping custom ASCII.
    #
    # Given as raw truecolor ANSI rather than the "red"/"black" palette
    # names: those resolve against the terminal's own 16-colour palette,
    # which stylix rewrites, so "red" came out muted and "black" landed on
    # #0d1117 -- the same value as foot's background, i.e. invisible. These
    # are absolute values and render the same regardless of the palette.
    programs.fastfetch = {
      enable = true;
      settings = {
        logo = {
          source = "nixos";
          color = {
            "1" = "38;2;255;45;45";      # vivid red
            "2" = "38;2;125;125;125";    # mid grey, reads as the dark half
          };
        };
      };
    };

    # No `gtk` block here on purpose: stylix's gtk target sets gtk.enable,
    # gtk.font and gtk.theme, and stylix.icons (see stylix.nix) sets
    # gtk.iconTheme -- which is what used to be hand-written here to fix
    # the blank/checkerboard icons.

    # Qt is the one thing left hand-set. Stylix's qt target defaults to off
    # unless it's handed a `nixosConfig`, which finix's home-manager doesn't
    # pass (it passes `osConfig`), so nothing collides here. Left on gtk3
    # rather than force-enabling that target: gtk3 makes Qt apps follow the
    # GTK theme stylix already themes, whereas the target would pull in
    # qtct + kvantum and expect QT_QPA_PLATFORMTHEME in the session env --
    # which on finix means another security.pam.environment entry, since a
    # greetd -> niri session never sources home-manager's session vars.
    qt = {
      enable = true;
      platformTheme.name = "gtk3";
    };
  };
}
