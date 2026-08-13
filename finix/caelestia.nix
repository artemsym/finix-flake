# caelestia-shell (niri port) -- NOT currently imported by configuration.nix.
#
# Builds up to the point of the QML plugin: the pinned nixpkgs' `libcava`
# doesn't ship a `cava.pc`, which the plugin's CMakeLists.txt requires via
# `pkg_check_modules(cava)`. Re-enable by adding `./caelestia.nix` to
# configuration.nix's imports once that's sorted (either nixpkgs ships a
# `cava.pc` again, or this gets patched to point at a different cava build).
#
# On gothness this came in through the upstream home-manager module, which
# starts the shell as a systemd *user* service -- finix has none, so only
# the package and its shell.json are wired up here; the actual launch would
# happen via niri's spawn-at-startup (see home.nix) once the package builds.
#
# The app2unit override is carried over from gothness: upstream's
# nix/app2unit.nix pins 1.0.3 but inherits nixpkgs' postFixup for the current
# version, whose substituteInPlace pattern doesn't exist in 1.0.3 -> build
# failure. Plain nixpkgs app2unit avoids it.
{ inputs, pkgs, ... }:
let
  caelestia =
    (inputs.niri-caelestia-shell.packages.${pkgs.stdenv.hostPlatform.system}.caelestia-shell.override {
      app2unit = pkgs.app2unit;
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
