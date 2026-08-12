# v2rayA, ported from gothness's:
#   services.v2raya.enable = true;
#   services.v2raya.cliPackage = pkgs.xray;
#   systemd.services.v2raya.path = [ iptables nftables iproute2 bash ];
#   systemd.services.v2raya.serviceConfig.AmbientCapabilities/CapabilityBoundingSet
#     = [ CAP_NET_ADMIN CAP_NET_BIND_SERVICE ];
#
# finix has no v2rayA module, so this hand-writes a `finit.services.v2raya`
# stanza. Confidence levels, since none of this was build-tested (no nix
# available in the sandbox this was written in):
#
#   - HIGH: the `caps`/`user`/`group`/`path`/`conditions` shape below is
#     copied from finix's own real-world example of an unprivileged
#     network daemon needing a capability -- see modules/services/blocky,
#     which does `caps = [ "^cap_net_bind_service" ]` for its own
#     privileged-port bind. Same pattern here, plus `^cap_net_admin` for
#     the iptables/routing work v2rayA's transparent-proxy mode needs.
#   - CONFIRMED: `pkgs.v2raya` (lowercase) is the correct nixpkgs attribute
#     -- `nix search` found `legacyPackages.x86_64-linux.v2raya` (2.2.7.5).
#   - MEDIUM: dropping `xray` into the service's `path` so v2rayA finds it
#     by searching $PATH, instead of passing it an explicit flag/env var --
#     nixpkgs' module wires `cliPackage` through some flag/env var
#     internally that isn't reproduced here. If v2rayA starts but can't
#     find/launch its xray core, that's almost certainly it -- check what
#     nixpkgs' upstream `services.v2raya` module actually passes for
#     `cfg.cliPackage` and mirror it into `command`/`environment` below.
#
# No firewall is configured on finix yet (see the note in desktop.nix), so
# nothing needs opening for v2rayA's web UI (port 2017 by default).
{ pkgs, ... }:
{
  finit.services.v2raya = {
    user = "v2raya";
    group = "v2raya";

    description = "v2rayA transparent proxy manager";
    conditions = [
      "service/syslogd/ready"
      "net/route/default"
    ];
    command = "${pkgs.v2raya}/bin/v2raya";
    path = with pkgs; [
      iptables
      nftables
      iproute2
      bash
      xray
    ];
    caps = [
      "^cap_net_admin"
      "^cap_net_bind_service"
    ];
    log = true;
    nohup = true;
  };

  users.users.v2raya = {
    isSystemUser = true;
    group = "v2raya";
  };
  users.groups.v2raya = { };
}
