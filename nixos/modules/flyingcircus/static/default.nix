{ lib, ... }:
with lib;
{
  options = {

    flyingcircus.static = mkOption {
      type = types.attrsOf types.attrs;
      default = { };
      description = "Static lookup tables for site-specific information";
    };

  };

  config = {

    flyingcircus.static.locations = {
      "whq" = { id = 0; site = "Halle"; };
      "yard" = { id = 1; site = "Halle"; };
      "rzob" = { id = 2; site = "Oberhausen"; };
      "dev" = { id = 3; site = "Halle"; };
      "rzrl1" = { id = 4; site = "Norderstedt"; };
    };

    # Note: this list of VLAN classes should be kept in sync with
    # fc.directory/src/fc/directory/vlan.py
    flyingcircus.static.vlans = {
      # management (grey): BMC, switches, tftp, remote console
      "1" = "mgm";
      # frontend (yellow): access from public Internet
      "2" = "fe";
      # servers/backend (red): RG-internal (app, database, ...)
      "3" = "srv";
      # storage (black): VM storage access (Ceph)
      "4" = "sto";
      # transfer (blue): primary router uplink
      "6" = "tr";
      # storage backend (yellow): Ceph replication and migration
      "8" = "stb";
      # transfer 2 (blue): secondary router-router connection
      "14" = "tr2";
      # gocept office
      "15" = "gocept";
      # frontend (yellow): additional fe needed on some switches
      "16" = "fe2";
      # servers/backend (red): additional srv needed on some switches
      "17" = "srv2";
      # transfer 3 (blue): tertiary router-router connection
      "18" = "tr3";
      # dynamic hardware pool: local endpoints for Kamp DHP tunnels
      "19" = "dhp";
    };

    flyingcircus.static.nameservers = {
      # ns.$location.gocept.net, ns2.$location.gocept.net
      # We are currently not using IPv6 resolvers as we have seen obscure bugs
      # when enabling them, like weird search path confusion that results in
      # arbitrary negative responses, combined with the rotate flag.
      #
      # This seems to be https://sourceware.org/bugzilla/show_bug.cgi?id=13028
      # which is fixed in glibc 2.22 which is included in NixOS 16.03.
      dev = [ "172.20.2.1" "172.20.3.7" "172.20.3.57" ];
      whq = [ "212.122.41.129" "212.122.41.173" "212.122.41.169" ];
      rzob = [ "195.62.125.1" "195.62.126.130" "195.62.126.131" ];
      rzrl1 = [ "84.46.82.1" "172.24.48.2" "172.24.48.10" ];

      # We'd like to add reliable open and trustworthy DNS servers here, but
      # I didn't find reliable ones. FoeBud and Germany Privacy Foundation and
      # others had long expired listings and I don't trust the remaining ones
      # to stay around. So, Google DNS it is.
      standalone = [ "8.8.8.8" "8.8.4.4" ];
    };

    flyingcircus.static.directory = {
      proxy_ips = [
        "195.62.125.11"
        "195.62.125.243"
        "195.62.125.6"
        "2a02:248:101:62::108c"
        "2a02:248:101:62::dd"
        "2a02:248:101:63::d4"
      ];
    };

    flyingcircus.static.firewall = {
      trusted = [
        # vpn-rzob.services.fcio.net
        "172.22.49.56"
        "195.62.126.69"
        "2a02:248:101:62::1187"
        "2a02:248:101:63::118f"

        # vpn-whq.services.fcio.net
        "172.16.48.35"
        "212.122.41.150"
        "2a02:238:f030:102::1043"
        "2a02:238:f030:103::1073"

        # Office
        "213.187.89.32/29"
        "2a02:238:f04e:100::/56"
      ];
    };

    flyingcircus.static.ntpservers = {
      # Those are the routers and backup servers. This needs to move to the
      # directory service discovery or just make them part of the router and
      # backup server role.
      dev = [ "eddie" "kenny00" ];
      whq = [ "lou" "kenny01" ];
      rzob = [ "kenny06" "kenny07" ];
      rzrl1 = [ "kenny02" "kenny03" ];
      # Location-independent NTP servers from the global public pool.
      standalone = [ "0.pool.ntp.org" "1.pool.ntp.org" "2.pool.ntp.org" ];
    };

    # Generally allow DHCP?
    flyingcircus.static.allowDHCP = {
      standalone = true;
      vagrant = true;
    };
    ids.uids = {
      # Sames as upstream/master, but not yet merged
      kibana = 211;
      turnserver = 249;
      prometheus = 255;
      telegraf = 256;

      # Our custom services
      sensuserver = 31001;
      sensuapi = 31002;
      uchiwa = 31003;
      sensuclient = 31004;
      powerdns = 31005;
      graylog = 31006;
    };

    ids.gids = {
      users = 100;
      # The generic 'service' GID is different from Gentoo.
      # But 101 is already used in NixOS.

      # Sames as upstream/master, but not yet merged
      prometheus = 255;

      service = 900;

      # Sames as upstream/master, but not yet merged
      turnserver = 249;

      # Our permissions
      login = 500;
      code = 501;
      stats = 502;
      sudo-srv = 503;
      manager = 504;

      # Our custom services
      sensuserver = 31001;
      sensuapi = 31002;
      uchiwa = 31003;
      sensuclient = 31004;
    };

  };
}
