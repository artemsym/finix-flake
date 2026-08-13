# Bits ported from the gothness NixOS config that have a finix equivalent.
# Kept in their own file so one bad option here can be dropped without
# touching the desktop.nix that already works.
{ pkgs, ... }:
{
  # X11 apps under Wayland (Steam, Discord, older Electron). Also fixes the
  # "X11 directory is not writable" error niri logs at startup without it.
  programs.xwayland-satellite.enable = true;

  # suspend / sleep backend
  programs.zzz.enable = true;

  # graphical polkit prompts (mounting disks, NetworkManager, ...) --
  # replaces gothness's hyprpolkitagent, which it ran as a systemd user
  # service. Requires services.elogind + services.polkit (see desktop.nix
  # and polkit-fix.nix).
  services.soteria.enable = true;

  # run unpatched/foreign binaries -- ported from gothness's programs.nix-ld.
  # `systemd`/`udev` from the original library list are swapped for `eudev`,
  # which is what finix actually ships and what provides libudev.so.1.
  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    alsa-lib at-spi2-atk at-spi2-core atk cairo cups curl dbus expat ffmpeg
    fontconfig freetype gdk-pixbuf glib gtk3 libGL libdrm libepoxy libnotify
    libpulseaudio libsecret libxkbcommon mesa nss nspr openssl pango
    stdenv.cc.cc.lib eudev vulkan-loader wayland zlib krb5
  ];

  # Session-wide variables. These go through PAM rather than
  # environment.variables: the latter only lands in /etc/profile.d, which a
  # greetd -> niri session never sources.
  security.pam.environment = {
    NIXOS_OZONE_WL.default = "1";          # Electron/VSCode on native Wayland
    LIBVA_DRIVER_NAME.default = "nvidia";
    NVD_BACKEND.default = "direct";
  };

  environment.systemPackages = with pkgs; [
    # swayidle drives the idle timeout (see the spawn-at-startup in
    # home.nix); the actual lock screen is caelestia's, triggered over its
    # IPC. swaylock is the standalone fallback if caelestia ever comes out.
    swaylock swayidle
    pavucontrol          # the audio app the caelestia config points at
    papirus-icon-theme
    libnotify
  ];
}
