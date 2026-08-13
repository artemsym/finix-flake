# Desktop bits ported from the `gothness` NixOS system (github.com/artemsym/nixos).
#
# Session stack: greetd + tuigreet (Wayland-native TUI greeter) -> niri.
# SDDM was the original attempt but its X11 greeter hung on this monitor's
# EDID during mode validation (a bug in nvidia's closed-source X driver
# blob, reproduced with both the open and closed kernel module -- see
# nvidia-modevalidation.nix); greetd/tuigreet never touches Xorg at all, so
# it sidesteps the bug entirely.
#
# Seat management: elogind, not seatd. This matters -- elogind pairs with
# `udev`, seatd pairs with `mdevd`; picking the wrong one leaves niri's
# session forever "not active" (see finix-community/community-modules'
# profiles.laptop for the canonical pairing). polkit also requires elogind
# (logind) to track sessions; without it polkit's finit service crash-loops.
#
# Still not ported (see ./caelestia.nix, kept but not imported, and
# ./home.nix's spawn-at-startup list):
#   - caelestia-shell (the bar/launcher/lock UI) -- builds, but the current
#     nixpkgs pin's `libcava` doesn't ship a cava.pc, which the plugin's
#     cmake needs. Package is otherwise wired up in caelestia.nix.
#   - the custom SDDM Qt greeter theme -- moot now that SDDM isn't used.
#   - Steam as a NixOS module (firewall ports, controller udev rules) --
#     no `programs.steam` in finix. `pkgs.steam` is added as a plain
#     package below, which covers basic launching but not the extras.
#   - printing (cups) and libvirtd/virt-manager -- finix has no modules for
#     either yet.
#   - zramSwap and `networking.firewall.*` -- no matching finix options
#     (v2ray.nix manages its own iptables/nftables rules instead).
{ config, pkgs, ... }:
{
  services.networkmanager.enable = true;

  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "ru_RU.UTF-8";
    LC_IDENTIFICATION = "ru_RU.UTF-8";
    LC_MEASUREMENT = "ru_RU.UTF-8";
    LC_MONETARY = "ru_RU.UTF-8";
    LC_NAME = "ru_RU.UTF-8";
    LC_NUMERIC = "ru_RU.UTF-8";
    LC_PAPER = "ru_RU.UTF-8";
    LC_TELEPHONE = "ru_RU.UTF-8";
    LC_TIME = "ru_RU.UTF-8";
  };

  # ===== niri + greetd/tuigreet =====
  programs.niri.enable = true;
  programs.tuigreet.enable = true;
  services.elogind.enable = true;
  fonts.fontconfig.enable = true;

  # ===== Audio (pipewire) =====
  programs.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    jack.enable = true;
  };
  programs.wireplumber.enable = true;
  services.rtkit.enable = true;

  # ===== Bluetooth =====
  services.bluetooth = {
    enable = true;
    settings.General.Enable = "Source,Sink,Media,Socket";
  };

  # ===== Network discovery =====
  services.avahi.enable = true;

  # ===== 32-bit graphics (Steam, Wine, ...) =====
  hardware.graphics.enable32Bit = true;

  # ===== Gaming =====
  programs.gamemode.enable = true;

  # ===== Power / thermal / OOM =====
  services.thermald.enable = true;
  services.earlyoom = {
    enable = true;
    # equivalent of gothness's freeMemThreshold=5 / freeSwapThreshold=10 (percent)
    extraArgs = [ "-m" "5" "-s" "10" ];
  };
  services.fstrim.enable = true;

  # ===== Removable media / battery status =====
  services.udisks2.enable = true;
  services.upower.enable = true;

  # Apple keyboard (vendor 05ac, product 024f): F1-F12 send their fn-media
  # actions (brightness/dashboard/kbd-illum/media/volume) by default. Force
  # the F-row to always send plain F1-F12 instead. Ported from gothness's
  # `services.udev.extraHwdb`, which finix doesn't have -- same hwdb rule,
  # shipped as a udev package instead.
  services.udev.packages = [
    (pkgs.writeTextDir "lib/udev/hwdb.d/61-apple-keyboard-fn.hwdb" ''
      evdev:input:b*v05ACp024F*
       KEYBOARD_KEY_7003a=f1
       KEYBOARD_KEY_7003b=f2
       KEYBOARD_KEY_7003c=f3
       KEYBOARD_KEY_7003d=f4
       KEYBOARD_KEY_7003e=f5
       KEYBOARD_KEY_7003f=f6
       KEYBOARD_KEY_70040=f7
       KEYBOARD_KEY_70041=f8
       KEYBOARD_KEY_70042=f9
       KEYBOARD_KEY_70043=f10
       KEYBOARD_KEY_70044=f11
       KEYBOARD_KEY_70045=f12
    '')
  ];

  # ===== Fonts =====
  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-color-emoji
    liberation_ttf
    dejavu_fonts
    font-awesome
    comic-mono
    cascadia-code
    victor-mono
    nerd-fonts.jetbrains-mono
    corefonts
  ];

  environment.systemPackages = with pkgs; [
    # --- CLI ---
    htop btop tree file unzip zip p7zip unrar
    ripgrep fd fzf fastfetch tmux rsync jq ncdu bat eza tldr lsof psmisc
    pciutils usbutils lm_sensors nmap mtr whois dnsutils gnupg sshfs
    zoxide direnv duf xclip wl-clipboard mpvpaper yazi ffmpegthumbnailer
    cava unar poppler xwayland-satellite satty linux-wallpaperengine

    # --- Development ---
    python3

    # --- GUI ---
    hicolor-icon-theme adwaita-icon-theme
    firefox vlc virt-manager gimp inkscape vscode
    obs-studio qbittorrent gparted
    dconf-editor blueman

    # --- Gaming (no NixOS steam module on finix -- see note at top) ---
    steam steam-run appimage-run libepoxy

    # --- Media ---
    telegram-desktop playerctl mpv ffmpeg yt-dlp imagemagick

    # --- Reading ---
    zotero calibre onlyoffice-desktopeditors zathura

    # --- Text ---
    pandoc bibata-cursors

    # --- Niri / Wayland utils ---
    foot starship wofi
    grim slurp fftw

    # --- Misc ---
    flatpak desktop-file-utils xdg-utils
  ];

  xdg.portal = {
    enable = true;
    portals = with pkgs; [ xdg-desktop-portal-gtk ];
  };
}
