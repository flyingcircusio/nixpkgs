/* This reworks the basic NixOS firewall.

   Specifically we have slightly different semantics:

   The default "open this port" directives (allowedTCPPorts and friends) are
   worthless to us. We need to explicitly differentiate between internal and
   external services, i.e. mark any statements appropriately between FE and
   SRV. Internal is opened up to neighbour VMs anyway. Public needs to be
   explicitly marked by our roles, not the general module.

   We thus disable the default NixOS firewall rules, and provide an alternative
   implementation here. This is basically a copy of the default, reduced by
   the stuff we do not want.

*/

{ config, lib, pkgs, ... }:

with lib;
with builtins;

let

  cfg = config.networking.firewall;

  helpers =
    ''
      # Helper command to manipulate both the IPv4 and IPv6 tables.
      ip46tables() {
        iptables -w "$@"
        ${optionalString config.networking.enableIPv6 ''
          ip6tables -w "$@"
        ''}
      }
    '';

  rg =
    let
      cfg = config.flyingcircus;
      fclib = import ../../lib;
      addrs_srv = map (elem: elem.ip) cfg.enc_addresses.srv;
      addrs_fe = map (elem: elem.ip) cfg.enc_addresses.fe;
      rule = eth: a: ''
        ${fclib.iptables a} -A nixos-fw -i ${eth} -s ${fclib.stripNetmask a
          } -j nixos-fw-accept
      '';
      rules_for = eth: addrs:
        (lib.concatMapStrings
          (rule eth)
          addrs);
      rules_srv = lib.optionalString
        (lib.hasAttr "ethsrv" config.networking.interfaces)
        (rules_for "ethsrv" addrs_srv);
      rules_fe = lib.optionalString
        (lib.hasAttr "ethfe" config.networking.interfaces)
        (rules_for "ethfe" addrs_fe);
      rules_srv_to_fe = lib.optionalString
        (lib.hasAttr "ethfe" config.networking.interfaces)
        (rules_for "ethfe" addrs_srv);
    in ''
      # Accept traffic within the same resource group.
      ${rules_srv}
      ${rules_fe}
      # Accept traffic from other SRV to our FE
      ${rules_srv_to_fe}
    '';


  writeShScript = name: text: let dir = pkgs.writeScriptBin name ''
    #! ${pkgs.stdenv.shell} -e
    ${text}
  ''; in "${dir}/bin/${name}";

  startScript = writeShScript "firewall-start" ''
    ${helpers}

    # Flush the old firewall rules.  !!! Ideally, updating the
    # firewall would be atomic.  Apparently that's possible
    # with iptables-restore.
    ip46tables -D INPUT -j nixos-fw 2> /dev/null || true
    for chain in nixos-fw nixos-fw-accept nixos-fw-log-refuse nixos-fw-refuse FW_REFUSE; do
      ip46tables -F "$chain" 2> /dev/null || true
      ip46tables -X "$chain" 2> /dev/null || true
    done


    # The "nixos-fw-accept" chain just accepts packets.
    ip46tables -N nixos-fw-accept
    ip46tables -A nixos-fw-accept -j ACCEPT


    # The "nixos-fw-refuse" chain rejects or drops packets.
    ip46tables -N nixos-fw-refuse

    ${if cfg.rejectPackets then ''
      # Send a reset for existing TCP connections that we've
      # somehow forgotten about.  Send ICMP "port unreachable"
      # for everything else.
      ip46tables -A nixos-fw-refuse -p tcp ! --syn -j REJECT --reject-with tcp-reset
      ip46tables -A nixos-fw-refuse -j REJECT
    '' else ''
      ip46tables -A nixos-fw-refuse -j DROP
    ''}


    # The "nixos-fw-log-refuse" chain performs logging, then
    # jumps to the "nixos-fw-refuse" chain.
    ip46tables -N nixos-fw-log-refuse

    ${optionalString cfg.logRefusedConnections ''
      ip46tables -A nixos-fw-log-refuse -p tcp --syn -j LOG --log-level info --log-prefix "rejected connection: "
    ''}
    ${optionalString (cfg.logRefusedPackets && !cfg.logRefusedUnicastsOnly) ''
      ip46tables -A nixos-fw-log-refuse -m pkttype --pkt-type broadcast \
        -j LOG --log-level info --log-prefix "rejected broadcast: "
      ip46tables -A nixos-fw-log-refuse -m pkttype --pkt-type multicast \
        -j LOG --log-level info --log-prefix "rejected multicast: "
    ''}
    ip46tables -A nixos-fw-log-refuse -m pkttype ! --pkt-type unicast -j nixos-fw-refuse
    ${optionalString cfg.logRefusedPackets ''
      ip46tables -A nixos-fw-log-refuse \
        -j LOG --log-level info --log-prefix "rejected packet: "
    ''}
    ip46tables -A nixos-fw-log-refuse -j nixos-fw-refuse


    # The "nixos-fw" chain does the actual work.
    ip46tables -N nixos-fw

    # Perform a reverse-path test to refuse spoofers
    # For now, we just drop, as the raw table doesn't have a log-refuse yet
    ${optionalString (kernelHasRPFilter && cfg.checkReversePath) ''
      if ! ip46tables -A PREROUTING -t raw -m rpfilter --invert -j DROP; then
        echo "<2>failed to initialise rpfilter support" >&2
      fi
    ''}

    # Accept all traffic on the trusted interfaces.
    ${flip concatMapStrings cfg.trustedInterfaces (iface: ''
      ip46tables -A nixos-fw -i ${iface} -j nixos-fw-accept
    '')}

    # Accept packets from established or related connections.
    ip46tables -A nixos-fw -m conntrack --ctstate ESTABLISHED,RELATED -j nixos-fw-accept

    # Accept IPv4 multicast.  Not a big security risk since
    # probably nobody is listening anyway.
    #iptables -A nixos-fw -d 224.0.0.0/4 -j nixos-fw-accept

    # Optionally respond to ICMPv4 pings.
    ${optionalString cfg.allowPing ''
      iptables -w -A nixos-fw -p icmp --icmp-type echo-request ${optionalString (cfg.pingLimit != null)
        "-m limit ${cfg.pingLimit} "
      }-j nixos-fw-accept
    ''}

    # Accept all ICMPv6 messages except redirects and node
    # information queries (type 139).  See RFC 4890, section
    # 4.4.
    ${optionalString config.networking.enableIPv6 ''
      ip6tables -A nixos-fw -p icmpv6 --icmpv6-type redirect -j DROP
      ip6tables -A nixos-fw -p icmpv6 --icmpv6-type 139 -j DROP
      ip6tables -A nixos-fw -p icmpv6 -j nixos-fw-accept
    ''}

    ip46tables -A nixos-fw -p tcp --dport 22 -j nixos-fw-accept

    ${rg}

    ${cfg.extraCommands}

    # Reject/drop everything else.
    ip46tables -A nixos-fw -j nixos-fw-log-refuse


    # Enable the firewall.
    ip46tables -A INPUT -j nixos-fw
  '';

  stopScript = writeShScript "firewall-stop" ''
    ${helpers}

    # Clean up in case reload fails
    ip46tables -D INPUT -j nixos-drop 2>/dev/null || true

    # Clean up after added ruleset
    ip46tables -D INPUT -j nixos-fw 2>/dev/null || true

    ${optionalString (kernelHasRPFilter && cfg.checkReversePath) ''
      if ! ip46tables -D PREROUTING -t raw -m rpfilter --invert -j DROP; then
        echo "<2>failed to stop rpfilter support" >&2
      fi
    ''}

    ${cfg.extraStopCommands}
  '';

  reloadScript = writeShScript "firewall-reload" ''
    ${helpers}

    # Create a unique drop rule
    ip46tables -D INPUT -j nixos-drop 2>/dev/null || true
    ip46tables -F nixos-drop 2>/dev/null || true
    ip46tables -X nixos-drop 2>/dev/null || true
    ip46tables -N nixos-drop
    ip46tables -A nixos-drop -j DROP

    # Don't allow traffic to leak out until the script has completed
    ip46tables -A INPUT -j nixos-drop
    if ${startScript}; then
      ip46tables -D INPUT -j nixos-drop 2>/dev/null || true
    else
      echo "Failed to reload firewall... Stopping"
      ${stopScript}
      exit 1
    fi
  '';

  kernelPackages = config.boot.kernelPackages;

  kernelHasRPFilter = kernelPackages.kernel.features.netfilterRPFilter or false;
  kernelCanDisableHelpers = kernelPackages.kernel.features.canDisableNetfilterConntrackHelpers or false;

in

{


  imports = [
    ./local.nix
  ];

  ###### implementation

  config = rec {

    # Keep the default firewall module disabled.
    networking.firewall.enable = false;
    networking.firewall.trustedInterfaces = [ "lo" ];

    networking.firewall.checkReversePath = false;  # replaced by own version

    # FC: basic policy
    networking.firewall.allowPing = true;
    networking.firewall.rejectPackets = true;

    environment.systemPackages = [ pkgs.iptables ] ++ cfg.extraPackages;

    boot.kernelModules = map (x: "nf_conntrack_${x}") cfg.connectionTrackingModules;
    boot.extraModprobeConfig = optionalString (!cfg.autoLoadConntrackHelpers) ''
      options nf_conntrack nf_conntrack_helper=0
    '';

    assertions = [ { assertion = ! cfg.checkReversePath || kernelHasRPFilter;
                     message = "This kernel does not support rpfilter"; }
                   { assertion = cfg.autoLoadConntrackHelpers || kernelCanDisableHelpers;
                     message = "This kernel does not support disabling conntrack helpers"; }
                 ];

    systemd.services.firewall = {
      description = "Firewall";
      wantedBy = [ "network-pre.target" ];
      before = [ "network-pre.target" ];
      after = [ "systemd-modules-load.service" ];

      path = [ pkgs.iptables ] ++ cfg.extraPackages;

      # FIXME: this module may also try to load kernel modules, but
      # containers don't have CAP_SYS_MODULE. So the host system had
      # better have all necessary modules already loaded.
      unitConfig.ConditionCapability = "CAP_NET_ADMIN";

      reloadIfChanged = true;

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "@${startScript} firewall-start";
        ExecReload = "@${reloadScript} firewall-reload";
        ExecStop = "@${stopScript} firewall-stop";
      };
    };

  };

}
