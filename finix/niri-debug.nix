# Extra tuigreet session entry that runs niri with RUST_LOG=debug and its
# full output redirected to /tmp/niri.log, since the normal niri.desktop
# session's stdout/stderr go nowhere finit captures. Pick "Niri (debug)" at
# the greeter (F2/F3 or arrow keys to switch sessions in tuigreet) when you
# need to see what actually happened, instead of just a blank screen.
{ config, pkgs, ... }:
{
  environment.systemPackages = [
    (pkgs.writeTextDir "share/wayland-sessions/niri-debug.desktop" ''
      [Desktop Entry]
      Name=Niri (debug)
      Comment=niri with full logging to /tmp/niri.log
      Exec=${pkgs.bash}/bin/bash -c "RUST_BACKTRACE=1 RUST_LOG=debug ${pkgs.dbus}/bin/dbus-run-session -- ${config.programs.niri.package}/bin/niri --session > /tmp/niri.log 2>&1"
      Type=Application
      DesktopNames=niri
    '')
  ];
}
