# v2rayA, ported from gothness's:
#   services.v2raya.enable = true;
#   services.v2raya.cliPackage = pkgs.xray;
#   systemd.services.v2raya.path = [ iptables nftables iproute2 bash ];
#   systemd.services.v2raya.serviceConfig.AmbientCapabilities/CapabilityBoundingSet
#     = [ CAP_NET_ADMIN CAP_NET_BIND_SERVICE ];
#
# finix has no v2rayA module, so this hand-writes a finit.services.v2raya
# stanza. Runs as root (no `user`/`caps` restriction) -- v2rayA's transparent
# proxy mode manages iptables/nftables rules directly and gothness's own
# systemd unit granted it CAP_NET_ADMIN/CAP_NET_BIND_SERVICE for the same
# reason. An earlier, more restrictive version tried to run it as a
# dedicated unprivileged user with just those two capabilities (mirroring
# finix's own `blocky` module) but that overcomplicated things for no
# measurable benefit here.
#
# Package attribute is `pkgs.v2raya` (lowercase a) but the actual binary
# inside is `bin/v2rayA` (capital A) -- confirmed by inspecting the built
# derivation; using the lowercase name here makes finit silently skip the
# service ("No such file or directory").
{ pkgs, ... }:
{
  finit.services.v2raya = {
    description = "v2rayA transparent proxy manager";
    conditions = "service/syslogd/ready";
    command = "${pkgs.v2raya}/bin/v2rayA";
    path = with pkgs; [ iptables nftables iproute2 bash xray ];
    log = true;
    nohup = true;
  };

  # Pin the package into the system profile so it isn't garbage-collected
  # out from under the finit service (which only referenced its store path
  # indirectly through the generated finit.d/v2raya.conf).
  environment.systemPackages = [ pkgs.v2raya ];
}
