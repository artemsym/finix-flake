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
  home-manager.users.goth = { pkgs, lib, osConfig, ... }:
  let
    # finix's pipewire and wireplumber modules install the packages and
    # write /etc config, but neither defines a finit service -- grep them
    # for "finit." and you get zero hits. Nothing on the system starts
    # either daemon, and there's no systemd user session to socket-activate
    # them the way NixOS does. So the session has to start them, or there
    # is no audio server running at all.
    #
    # That's what breaks bluetooth headsets: bluez accepts the pairing,
    # then finds no A2DP endpoint registered (registering it is
    # wireplumber's job) and drops the link a moment later -- while the
    # headphones themselves still think they're connected. Exactly the
    # connect/disconnect flap seen here.
    startAudio = pkgs.writeShellScript "start-audio-session" ''
      ${osConfig.programs.pipewire.package}/bin/pipewire &

      # pipewire-pulse and wireplumber both give up if pipewire's socket
      # isn't there yet, so wait for it instead of racing the startup.
      i=0
      while [ "$i" -lt 100 ]; do
        [ -S "$XDG_RUNTIME_DIR/pipewire-0" ] && break
        ${pkgs.coreutils}/bin/sleep 0.05
        i=$((i + 1))
      done

      ${osConfig.programs.pipewire.package}/bin/pipewire-pulse &
      ${osConfig.programs.wireplumber.package}/bin/wireplumber &

      wait
    '';

    # Static wallpaper, replacing linux-wallpaperengine (which only ever
    # played Steam Workshop items and needed them downloaded locally first).
    # swaybg is the plain wl-roots wallpaper setter and works under niri.
    #
    # Tries both capitalisations because ~/Downloads vs ~/downloads depends
    # on the locale the directory was created under, and picking the wrong
    # one just silently leaves the screen empty.
    setWallpaper = pkgs.writeShellScript "set-wallpaper" ''
      for f in "$HOME/Downloads/end.jpg" "$HOME/downloads/end.jpg"; do
        if [ -f "$f" ]; then
          exec ${pkgs.swaybg}/bin/swaybg -i "$f" -m fill
        fi
      done
      echo "set-wallpaper: no end.jpg under ~/Downloads or ~/downloads" >&2
      exit 1
    '';
  in
  {
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

        // pipewire + pipewire-pulse + wireplumber. Not a gothness port --
        // on NixOS services.pipewire.enable handles this. finix ships the
        // packages but starts nothing, so the session does it.
        spawn-at-startup "${startAudio}"

        // the bar/launcher/dashboard: was upstream's caelestia home-manager
        // module, whose unit runs the binary with no arguments (see
        // caelestia.nix).
        spawn-at-startup "caelestia-shell"

        // wallpaper: was systemd.user.services.wallpaper, which ran
        // linux-wallpaperengine against a Steam Workshop id. Now a plain
        // static image via swaybg -- see setWallpaper above.
        spawn-at-startup "${setWallpaper}"

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
    # The snowflake has six arms and fastfetch colours them from six slots,
    # not two -- setting only 1 and 2 recoloured a single arm each and left
    # the other four on the stock blues. All six are assigned here,
    # alternating so opposite arms match.
    programs.fastfetch = {
      enable = true;
      settings = {
        logo = {
          source = "nixos";
          color =
            let
              red = "38;2;255;45;45";
              dark = "38;2;125;125;125";
            in
            {
              "1" = red;  "2" = dark;
              "3" = red;  "4" = dark;
              "5" = red;  "6" = dark;
            };
        };

        # Matches the finix maintainer's output. His own config sets nothing
        # for fastfetch, so that's just the stock module set -- pinning it
        # here keeps the layout from drifting when fastfetch changes its
        # defaults. "initsystem" is the one worth keeping: on finix it
        # reports Finit rather than systemd.
        modules = [
          "title"
          "separator"
          "os"
          "host"
          "kernel"
          "initsystem"
          "uptime"
          "packages"
          "shell"
          "display"
          "wm"
          "theme"
          "icons"
          "font"
          "cursor"
          "terminal"
          "terminalfont"
          "cpu"
          "gpu"
          "memory"
          "swap"
          "disk"
          "localip"
          "locale"
          "break"
          "colors"
        ];
      };
    };

    # Autostart fastfetch on every interactive shell. initExtra lands in the
    # interactive branch of .bashrc, so it won't fire for scp/rsync and
    # other non-interactive sessions -- printing to those breaks them.
    #
    # Enabling home-manager's bash module here also finally wires up
    # starship: its module only injects the shell init when the matching
    # shell module is enabled, and until now none was.
    programs.bash = {
      enable = true;
      initExtra = ''
        ${pkgs.fastfetch}/bin/fastfetch
      '';
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
