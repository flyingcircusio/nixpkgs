{ config, lib, pkgs, ... }:

with builtins;

let
  cfg = config.flyingcircus;

  fclib = import ../lib;

  # generally use DHCP in the current location?
  allowDHCP = location:
    if hasAttr location cfg.static.allowDHCP
    then cfg.static.allowDHCP.${cfg.enc.parameters.location}
    else false;

  interfaces = lib.attrByPath [ "parameters" "interfaces" ] {} cfg.enc;
  location = lib.attrByPath [ "parameters" "location" ] "standalone" cfg.enc;

  # Policy routing

  rt_tables = ''
    # reserved values
    #
    255 local
    254 main
    253 default
    0 unspec
    #
    # local
    #
    ${lib.concatStringsSep "\n" (
      lib.mapAttrsToList (n : vlan : "${n} ${vlan}")
      cfg.static.vlans
    )}
    '';

  # Adapted 'ip' command which says what it is doing and ignores errno 2 (file
  # exists) to make it idempotent.
  relaxedIp = pkgs.writeScriptBin "ip" ''
    #! ${pkgs.stdenv.shell} -e
    echo ip "$@"
    rc=0
    ${pkgs.iproute}/bin/ip "$@" || rc=$?
    if ((rc == 2)); then
      exit 0
    else
      exit $rc
    fi
  '';

  # add srv addresses from my own resource group to /etc/hosts
  hostsFromEncAddresses = enc_addresses:
    let
      recordToEtcHostsLine = r:
        "${fclib.stripNetmask r.ip} ${r.name}.${config.networking.domain} ${r.name}";
    in
      # always mention IPv6 addresses first to get predictable behaviour
      lib.concatMapStringsSep "\n" recordToEtcHostsLine
        ((filter (a: fclib.isIp6 a.ip) enc_addresses) ++
         (filter (a: fclib.isIp4 a.ip) enc_addresses));

in

{
  options = {
    flyingcircus.network.policyRouting = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = !(pathExists "/etc/local/simplerouting");
        description = ''
          Enable policy routing? Touch /etc/local/simplerouting to turn policy
          routing off.
        '';
      };

      extraRoutes = lib.mkOption {
        description = ''
          Add the given routes to every routing table. List items should be
          "ip route" command fragments without a "ip -[46] route {add,del}"
          prefix and a "table" suffix.
        '';
        default = [ ];
        type = with lib.types; listOf str;
        example = [
          "10.107.36.0/24 via 10.107.36.2 dev tun0"
        ];
      };

      requires = lib.mkOption {
        description = ''
          List of systemd services which are required to run before policy
          routing is started (e.g., because they define additional network
          interfaces).

          Note that the policy routing services will go down if one of the
          required services goes down.
        '';
        default = [ ];
        type = with lib.types; listOf str;
        example = [ "openvpn.service" ];
      };

    };
  };

  config = rec {
    environment.etc."iproute2/rt_tables".text = rt_tables;
    environment.etc."host.conf".text = ''
      order hosts, bind
      multi on
    '';

    services.udev.extraRules =
      if (interfaces != {}) then
        lib.concatMapStrings
          (vlan:
            let
              fallback = "02:00:00:${fclib.byteToHex (lib.toInt n)}:??:??";
              mac = lib.toLower
                (lib.attrByPath [ vlan "mac" ] fallback interfaces);
            in ''
              KERNEL=="eth*", ATTR{address}=="${mac}", NAME="eth${vlan}"
            '')
          (attrNames interfaces)
      else ''
        # static fallback rules for VMs
        KERNEL=="eth*", ATTR{address}=="02:00:00:02:??:??", NAME="ethfe"
        KERNEL=="eth*", ATTR{address}=="02:00:00:03:??:??", NAME="ethsrv"
      '';

    networking.domain = "gocept.net";

    networking.nameservers =
      if (lib.hasAttrByPath [ "parameters" "location" ] cfg.enc) &&
         (hasAttr cfg.enc.parameters.location cfg.static.nameservers)
      then cfg.static.nameservers.${cfg.enc.parameters.location}
      else [];
    networking.resolvconfOptions = "ndots:1 timeout:1 attempts:4 rotate";

    networking.search =
      if lib.hasAttrByPath [ "parameters" "location" ] cfg.enc then
        [ "${cfg.enc.parameters.location}.${networking.domain}"
          networking.domain
        ]
      else [];

    # data structure for all configured interfaces with their IP addresses:
    # { ethfe = { ... }; ethsrv = { }; ... }
    networking.interfaces =
      lib.mapAttrs'
        (vlan: iface:
          lib.nameValuePair
            "eth${vlan}"
            (fclib.interfaceConfig iface.networks // { useDHCP = false; }))
        interfaces;

    systemd.services =
      let startStopScript = if cfg.network.policyRouting.enable
        then fclib.policyRouting
        else fclib.simpleRouting;
      in
      { nscd.restartTriggers = [
          config.environment.etc."host.conf".source
        ];
      } //
      listToAttrs
        (map
          (vlan: lib.nameValuePair
            "network-routing-eth${vlan}"
            rec {
              description = "Custom IP routing for eth${vlan}";
              requires = [ "network-addresses-eth${vlan}.service" ];
              after = requires;
              before = [ "network-local-commands.service" ];
              wantedBy = [ "network-interfaces.target" ];
              bindsTo = [ "sys-subsystem-net-devices-eth${vlan}.device" ];
              path = [ relaxedIp ];
              script = startStopScript {
                vlan = "${vlan}";
                encInterface = interfaces.${vlan};
              };
              preStop = startStopScript {
                vlan = "${vlan}";
                encInterface = interfaces.${vlan};
                action = "stop";
              };
              serviceConfig = {
                Type = "oneshot";
                RemainAfterExit = true;
              };
            })
          (attrNames interfaces)) //
      (lib.optionalAttrs (interfaces != {}) (listToAttrs
        (map (vlan:
          let
            mac = lib.toLower interfaces.${vlan}.mac;
          in
          lib.nameValuePair
            "network-no-autoconf-eth${vlan}"
            rec {
              description = "Disable IPv6 SLAAC (autconf) on eth${vlan}";
              wantedBy = [ "network-addresses-eth${vlan}.service" ];
              before = wantedBy;
              path = [ pkgs.nettools pkgs.procps ];
              script = ''
                nameif eth${vlan} ${mac}
                sysctl net.ipv6.conf.eth${vlan}.autoconf=0
              '';
              preStop = ''
                sysctl net.ipv6.conf.eth${vlan}.autoconf=1
              '';
              serviceConfig = {
                Type = "oneshot";
                RemainAfterExit = true;
              };
            })
          (attrNames interfaces))));

    # firewall configuration: generic options
    networking.firewall.allowPing = true;
    networking.firewall.rejectPackets = true;

    # DHCP settings: never do IPv4ll and don't use DHCP if there is explicit
    # network configuration present
    networking.useDHCP =
      (interfaces == {}) || (allowDHCP cfg.enc.parameters.location);
    networking.dhcpcd.extraConfig = ''
      # IPv4ll gets in the way if we really do not want
      # an IPv4 address on some interfaces.
      noipv4ll
    '';

    networking.extraHosts = lib.optionalString
      (cfg.enc_addresses.srv != [])
      (hostsFromEncAddresses cfg.enc_addresses.srv);

    boot.kernel.sysctl = {
      "net.ipv4.ip_local_port_range" = "32768 60999";
      "net.ipv4.ip_local_reserved_ports" = "61000-61999";
      # work around CVE-2016-5696
      # obsolete on Linux 4.7+
      "net.ipv4.tcp_challenge_ack_limit" = "999999999";
    };
  };
}
