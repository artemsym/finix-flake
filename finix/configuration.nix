{ config, pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./desktop.nix
    ./v2ray.nix
    ./nvidia-modevalidation.nix
    ./niri-debug.nix
    ./polkit-fix.nix
    ./extras.nix
    ./home.nix
    ./stylix.nix
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
    openssh.enable = true;
  };

  # RTX 2070: the closed proprietary driver is what's proven to work on this
  # exact GPU + monitor combo (same driver gothness runs). The open kernel
  # module loads fine too, but the userspace X11 mode-validation code (which
  # is the same closed-source blob either way) hits an unrelated hang on this
  # monitor -- see nvidia-modevalidation.nix.
  hardware.nvidia = {
    enable = true;
    kernelModule = "closed";
  };
  hardware.graphics.enable = true;

  # Belt-and-suspenders blacklist: finix's hardware.nvidia module already
  # blacklists nouveau via /etc/modprobe.d, but that file isn't guaranteed to
  # be in place before the initrd's own module autoprobing runs. Passing it
  # on the kernel cmdline (what NixOS's boot.blacklistedKernelModules does
  # under the hood, an option finix doesn't have) blocks it unconditionally.
  boot.kernelParams = [ "modprobe.blacklist=nouveau" "nouveau.modeset=0" ];

  # Covers WiFi/other device firmware that isn't baked into the kernel
  # itself. finix's own install docs call this out as the fix for wifi
  # cards not showing up.
  hardware.firmware = [ pkgs.linux-firmware ];

  networking.hostName = "finixos";
  time.timeZone = "Europe/Moscow";

  users.users.goth = {
    isNormalUser = true;
    description = "goth";
    extraGroups = [ "wheel" "video" "audio" "networkmanager" "input" "render" ];
    # hashed password -- generate your own with `mkpasswd -m sha-512`
    password = "$6$QJ3Ex.kogucotWwQ$l/m0lydG91nZbfM5Um899RSNaQkEWxp.6zaoyWHp7kaLhYs7z2tE/SnpnqciVdKOmzmTC15H51Kp.ACpw4p0..";
    packages = with pkgs; [];
  };

  environment.systemPackages = with pkgs; [
    vim wget git nixos-rebuild-ng iputils iproute2
  ];
}
