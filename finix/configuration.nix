{ config, pkgs, ... }:
{
  imports = [ ./hardware-configuration.nix ];

  boot.kernelPackages = pkgs.linuxPackages_latest;
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
    mdevd.enable = true;
    dhcpcd.enable = true;
    iwd.enable = true;
  };

  networking.hostName = "finixos";
  time.timeZone = "Europe/Moscow";

  users.users.goth = {
    isNormalUser = true;
    description = "goth";
    extraGroups = [ "wheel" ];
    hashedPassword = "$6$QJ3Ex.kogucotWwQ$l/m0lydG91nZbfM5Um899RSNaQkEWxp.6zaoyWHp7kaLhYs7z2tE/SnpnqciVdKOmzmTC15H51Kp.ACpw4p0..";
    packages = with pkgs; [];
  };

  environment.systemPackages = with pkgs; [
    vim wget git nixos-rebuild-ng iputils iproute2
  ];
}
