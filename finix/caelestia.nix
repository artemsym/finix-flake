# caelestia-shell (niri port) -- the bar/launcher/dashboard, replacing what
# waybar did on gothness.
#
# Two things had to be fixed to get this working on finix; both are below.
#
# On gothness this came in through upstream's home-manager module, which
# starts the shell as a systemd *user* service. finix has no systemd user
# session, so only the package and its config are wired up here and niri's
# spawn-at-startup does the launching (see home.nix). Upstream's unit runs
# plain `${shell}/bin/caelestia-shell` with no arguments, so that's exactly
# what spawn-at-startup runs.
{ inputs, pkgs, ... }:
let
  # Fix 1: the plugin doesn't build against libcava 0.10.7, which is what
  # nixpkgs-unstable carries. Two independent breaks, both introduced by
  # that one release:
  #
  #   * 0.10.7 made `struct cava_plan` opaque. The installed header
  #     (include/cava/cavacore.h) only forward-declares it now, where 0.10.6
  #     spelled the struct out in full. cavaprovider.cpp reads
  #     `m_plan->status` directly, so against 0.10.7 that's a hard
  #     "member access into incomplete type 'struct cava_plan'".
  #
  #   * 0.10.7 also renamed its pkg-config file -- meson's pkg.generate went
  #     from `filebase: 'cava'` to `filebase: 'libcava'` -- so the plugin's
  #     `pkg_check_modules(Cava IMPORTED_TARGET cava REQUIRED)` finds
  #     nothing and cmake fails before it even gets to the compile error.
  #
  # Both go away by pinning 0.10.6, which is what nixos-26.05 ships and
  # therefore exactly the pairing gothness builds against today. Version and
  # hash are lifted verbatim from that release's own
  # pkgs/by-name/li/libcava/package.nix, so this isn't a guessed hash.
  libcava_0_10_6 = pkgs.libcava.overrideAttrs (_: rec {
    version = "0.10.6";
    src = pkgs.fetchFromGitHub {
      owner = "LukashonakV";
      repo = "cava";
      tag = version;
      hash = "sha256-63be1wypMiqhPA6sjMebmFE6yKpTj/bUE53sMWun554=";
    };
  });

  # Fix 2: caelestia hardcodes app2unit for every app it launches -- the
  # launcher, the audio popout, the calculator, notification links. app2unit
  # launches things via `systemd-run --user`, so on finix it fails and none
  # of those buttons do anything. This shim takes the same arguments and
  # just runs the command directly, which is all app2unit was buying us here
  # (its point is per-app systemd scopes for resource control -- there's no
  # systemd to put them in).
  #
  # It also replaces the app2unit override carried over from gothness:
  # upstream's own nix/app2unit.nix pins 1.0.3 while inheriting nixpkgs'
  # postFixup for a newer version, whose substituteInPlace pattern doesn't
  # exist in 1.0.3 -> build failure.
  app2unitShim = pkgs.writeShellScriptBin "app2unit" ''
    # app2unit [-O|--open] [other flags] -- command...
    open=0
    while [ "$#" -gt 0 ]; do
      case "$1" in
        --) shift; break ;;
        -O|--open) open=1; shift ;;
        -*) shift ;;
        *) break ;;
      esac
    done

    if [ "$open" -eq 1 ]; then
      exec ${pkgs.xdg-utils}/bin/xdg-open "$@"
    fi
    exec "$@"
  '';

  caelestia =
    (inputs.niri-caelestia-shell.packages.${pkgs.stdenv.hostPlatform.system}.caelestia-shell.override {
      app2unit = app2unitShim;
      libcava = libcava_0_10_6;
      withCli = true;
    });
in
{
  home-manager.users.goth = {
    home.packages = [ caelestia ];

    xdg.configFile."caelestia/cli.json".text = "{}";
    xdg.configFile."caelestia/shell.json".text = builtins.toJSON {
      appearance = {
        anim.durations.scale = 1;
        font = {
          family = {
            material = "Material Symbols Rounded";
            mono = "CaskaydiaCove NF";
            sans = "Rubik";
          };
          size.scale = 1;
        };
        padding.scale = 1;
        rounding.scale = 1;
        spacing.scale = 1;
        transparency = { enabled = false; base = 0.85; layers = 0.4; };
      };

      general.apps = {
        terminal = [ "foot" ];
        audio = [ "pavucontrol" ];
      };

      background = {
        desktopClock.enabled = false;
        enabled = false;
        visualiser = { enabled = true; autoHide = true; rounding = 1; spacing = 1; };
      };

      bar = {
        clock.showIcon = false;
        dragThreshold = 20;
        entries = [
          { id = "logo"; enabled = true; }
          { id = "workspaces"; enabled = true; }
          { id = "spacer"; enabled = true; }
          { id = "activeWindow"; enabled = true; }
          { id = "spacer"; enabled = true; }
          { id = "tray"; enabled = true; }
          { id = "clock"; enabled = true; }
          { id = "statusIcons"; enabled = true; }
          { id = "power"; enabled = true; }
          { id = "idleInhibitor"; enabled = false; }
        ];
        persistent = false;
        showOnHover = true;
        status = {
          showAudio = false; showBattery = true; showBluetooth = true;
          showMicrophone = false; showKbLayout = false; showNetwork = true;
        };
        tray = { background = true; recolour = true; };
        workspaces = {
          activeIndicator = true;
          activeLabel = "󰮯";
          activeTrail = false;
          groupIconsByApp = true;
          groupingRespectsLayout = true;
          windowRighClickContext = true;
          label = "◦";
          occupiedBg = true;
          occupiedLabel = "⊙";
          showWindows = true;
          shown = 4;
          windowIconImage = true;
          focusedWindowBlob = true;
          windowIconGap = 0;
          windowIconSize = 30;
        };
      };

      border = { rounding = 25; thickness = 10; };
      dashboard = { mediaUpdateInterval = 500; showOnHover = true; };

      launcher = {
        actionPrefix = ">";
        dragThreshold = 50;
        vimKeybinds = false;
        enableDangerousActions = false;
        maxShown = 8;
        maxWallpapers = 9;
        specialPrefix = "@";
        useFuzzy = {
          apps = false; actions = false; schemes = false;
          variants = false; wallpapers = false;
        };
        showOnHover = false;
      };

      lock.recolourLogo = false;

      notifs = {
        actionOnClick = false;
        clearThreshold = 0.3;
        defaultExpireTimeout = 5000;
        expandThreshold = 20;
        expire = false;
      };

      osd = {
        enabled = true; enableBrightness = true;
        enableMicrophone = true; hideDelay = 2000;
      };

      paths = {
        mediaGif = "root:/assets/bongocat.gif";
        sessionGif = "root:/assets/kurukuru.gif";
        wallpaperDir = "~/Pictures/Wallpapers";
      };

      services = {
        audioIncrement = 0.1;
        defaultPlayer = "Spotify";
        gpuType = "";
        playerAliases = [
          { from = "com.github.th_ch.youtube_music"; to = "YT Music"; }
        ];
        weatherLocation = "Saint-Petersburg";
        useFahrenheit = false;
        useTwelveHourClock = false;
        smartScheme = true;
        visualiserBars = 45;
      };

      # gothness drove these through systemctl; finix has elogind's loginctl.
      session = {
        dragThreshold = 30;
        vimKeybinds = false;
        commands = {
          logout = [ "loginctl" "terminate-user" "" ];
          shutdown = [ "loginctl" "poweroff" ];
          hibernate = [ "loginctl" "hibernate" ];
          reboot = [ "loginctl" "reboot" ];
        };
      };
    };
  };
}
