# Gateway to external networks. This includes VxLAN tunnels to Kamp DHP and
# OpenVPN.

# Assumes that the address ranges for network extensions are within
# - 10.0.0.0/8
# - fde6:1c0f:70c3::/48

{ config, lib, pkgs, ... }:

let
  cfg = config.flyingcircus;
  types = lib.types;
  stdenv = pkgs.stdenv;

in
{
  options = {
    flyingcircus.roles.external_net = {

      enable = lib.mkEnableOption {
        description = "Enable the Flying Circus external network gateway role";
      };

      vxlan = {
        vid = lib.mkOption {
          description = "VxLAN ID";
          type = types.nullOr types.int;
          example = 2;
          default = null;
        };

        net4 = lib.mkOption {
          description = ''
            IPv4 network range to allocate to VxLAN hosts via DHCP. Must be a
            subnet of 10.0.0.0/8.
          '';
          type = types.string;
          example = "10.1.2.0/24";
        };

        net6 = lib.mkOption {
          description = ''
            IPv6 network range to allocate to VxLAN hosts via RA. Must be a
            subnet of fde6:1c0f:70c3::/48.
          '';
          type = types.string;
          example = "fde6:1c0f:70c3:4c32::/64";
        };

        local = lib.mkOption {
          description = "Local VxLAN tunnel endpoint (IPv6 only)";
          type = types.string;
          example = "2001:db8:1:333::1";
        };

        remote = lib.mkOption {
          description = "Remote VxLAN tunnel endpoint (IPv6 only)";
          type = types.string;
          example = "2001:db8:222:111::1";
        };
      };
    };
  };

  config = lib.mkIf (
      cfg.roles.external_net.enable &&
      cfg.roles.external_net.vxlan.vid != null) (
    let
      vxlan_cfg = cfg.roles.external_net.vxlan;
      net4 = vxlan_cfg.net4;
      net6 = vxlan_cfg.net6;
      tunneldev = "nx0";
      ip = "${pkgs.iproute}/bin/ip";

      # This is a hack. Computing all the network nets and addresses with Nix is
      # a pain. Rather use a Python script which dumps the stuff into a JSON
      # which is read in turn into a Nix attrset.
      params = builtins.fromJSON (builtins.readFile (
        stdenv.mkDerivation {
          name = "external-network-params.json";
          # expects net4 and net6 as command line arguments, returns a JSON
          # containg all kinds of VxLAN/dnsmasq addresses/networks
          script = ''
            import json
            import ipaddress
            import sys
            net4, net6 = sys.argv[1:]
            i4 = ipaddress.ip_network(net4)
            i6 = ipaddress.ip_network(net6)
            print(json.dumps({
              'gw4': '{}/{}'.format(i4[1], i4.prefixlen),
              'gw6': '{}/{}'.format(i6[1], i6.prefixlen),
              'dhcp': (str(i4[2]), str(i4[-1])),
            }))
          '';
          passAsFile = [ "script" ];
          buildCommand = ''
            ${pkgs.python34}/bin/python3 $scriptPath ${net4} ${net6} > $out
          '';
        }).out);

      domain =
        if lib.hasAttrByPath [ "parameters" "resource_group" ] cfg.enc
        then "${cfg.enc.parameters.resource_group}.fcio.net"
        else "local";

      svc = {
        services.dnsmasq.enable = true;
        services.dnsmasq.extraConfig = ''
          dhcp-authoritative
          dhcp-fqdn
          dhcp-leasefile=/var/lib/dnsmasq.leases
          dhcp-option=option6:dns-server,[::]
          dhcp-option=option6:ntp-server,[::]
          dhcp-option=option:dns-server,0.0.0.0
          dhcp-option=option:mtu,1430
          dhcp-option=option:ntp-server,0.0.0.0
          dhcp-range=::,constructor:${tunneldev},ra-names
          dhcp-range=${lib.concatStringsSep "," params.dhcp},24h
          domain=${domain}
          domain-needed
          interface=${tunneldev}
          local-ttl=60
        '';

        services.chrony.extraConfig = ''
          allow 10.0.0.0/8
          allow fde6:1c0f:70c3::/48
        '';
      };

      firewall = {
        networking.firewall.allowedUDPPorts = [ 53 67 68 123 8472 ];
        networking.firewall.extraCommands = ''
          iptables -t nat -F POSTROUTING
          iptables -t nat -A POSTROUTING -s 10.0.0.0/8 -o ethfe -j MASQUERADE
          ip6tables -t nat -F POSTROUTING
          ip6tables -t nat -A POSTROUTING -s fde6:1c0f:70c3::/48 -o ethfe -j MASQUERADE
        '';
        boot.kernel.sysctl = { "net.ipv4.ip_forward" = true; };
      };
    in
      import ../../services/vxlan.nix {
        inherit (vxlan_cfg) vid local remote;
        inherit (params) gw4 gw6;
        inherit tunneldev lib pkgs;
      }
      // svc
      // firewall
    );
}
