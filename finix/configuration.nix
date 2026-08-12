{ config, pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./desktop.nix
    ./v2ray.nix
  ];

  # Stick to finix's default `pkgs.linuxPackages` (well-tested against the
  # current nvidia driver) instead of `linuxPackages_latest`. The bleeding
  # edge kernel often ships before nixpkgs' nvidia kernel-interface patches
  # catch up, which is the usual reason the nvidia .ko fails to compile.
  finit.runlevel = 3;
  finit.services.nix-daemon = {
    environment.CURL_CA_BUNDLE = config.security.pki.caBundle;
  };
  services.nix-daemon = {
    enable = true;
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      trusted-users = [ "root" "@wheel" ];
    };
  };

  boot.loader.efi.canTouchEfiVariables = true;
  programs = {
    limine = {
      enable = true;
      settings.editor_enabled = true;
    };
    sudo.enable = true;
    bash.enable = true;
  };
  services = {
    polkit.enable = true;
    sysklogd.enable = true;
    dbus.enable = true;
    # udev (not mdevd) so /dev/disk/by-id and /dev/disk/by-uuid actually get
    # populated -- with mdevd, filesystems have to be referenced by raw
    # kernel names (/dev/sda1), which isn't safe on a multi-disk machine
    # where drive letters can shift between boots. See the "mdevd" notes in
    # https://github.com/finix-community/examples/blob/main/installations/README.md
    udev.enable = true;
  };

  # Turing+ GPUs (RTX 20xx and newer) are best served by the open-source
  # kernel modules: they get patched for new kernels much faster than the
  # closed proprietary ones, which is what usually causes the .ko to fail
  # to build on a recent kernel.
  hardware.nvidia = {
    enable = true;
    kernelModule = "open";
  };
  hardware.graphics.enable = true;

  # Covers WiFi/other device firmware that isn't baked into the kernel
  # itself. finix's own install docs call this out as the fix for wifi
  # cards not showing up.
  hardware.firmware = [ pkgs.linux-firmware ];

  networking.hostName = "finixos";
  time.timeZone = "Europe/Moscow";

  users.users.goth = {
    isNormalUser = true;
    description = "goth";
    extraGroups = [ "wheel" "video" "audio" "networkmanager" ];
    hashedPassword = "$6$QJ3Ex.kogucotWwQ$l/m0lydG91nZbfM5Um899RSNaQkEWxp.6zaoyWHp7kaLhYs7z2tE/SnpnqciVdKOmzmTC15H51Kp.ACpw4p0..";
    packages = with pkgs; [];
  };

  environment.systemPackages = with pkgs; [
    vim wget git nixos-rebuild-ng iputils iproute2
  ];
}
