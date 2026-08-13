# finix's polkit module builds the polkit package with
# `useSystemd = !config.services.elogind.enable` (i.e. built *without*
# systemd support when elogind is enabled, which it is here -- see
# desktop.nix) but still tells finit to wait for a systemd-style readiness
# notification (`notify = "systemd"`) from a binary that can no longer send
# one. polkit crash-loops (10/10 restarts, gives up) until this is forced
# off. Root cause looks like an upstream finix oversight, not anything
# specific to this config.
{ lib, ... }:
{
  finit.services.polkit.notify = lib.mkForce "none";
  finit.services.polkit.log = true;
}
