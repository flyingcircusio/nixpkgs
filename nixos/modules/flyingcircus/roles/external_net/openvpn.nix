{ config, lib, pkgs, stdenv, ... }:

with builtins;

let
  fclib = import ../../lib;
  decomposeCIDR = fclib.decomposeCIDR pkgs;
  cfg = config.flyingcircus;
  extnet = cfg.roles.external_net;
  parameters = lib.attrByPath [ "enc" "parameters" ] {} cfg;
  interfaces = lib.attrByPath [ "interfaces" ] {} parameters;
  location = lib.attrByPath [ "location" ] null parameters;
  resource_group = lib.attrByPath [ "resource_group" ] null parameters;
  domain = config.networking.domain;
  id16bit = fclib.mod (lib.attrByPath [ "id" ] 0 parameters) 65536;

  defaultAccessNets = ''
    {
      "ipv4": "10.70.67.0/24",
      "ipv6": "fd3e:65c4:fc10:${fclib.toHex id16bit}::/64",
      "proto": "udp6",
      "extraroutes": []
    }
  '';

  ovpn = "${pki.caDir}/${frontendName}.ovpn";

  #
  # packages
  #
  inherit (pkgs) openvpn;
  easyrsa = pkgs.easyrsa3;
  pki = pkgs.callPackage ./generate-pki.nix {
    inherit easyrsa openvpn resource_group location;
  };

  #
  # addresses
  #
  # attrset of those fe addresses that have a reverse
  feReverses =
    # fake attrset from listenAddresses: { "addr" = null; ... }
    let feAddrSet =
      lib.genAttrs (fclib.listenAddresses config "ethfe") (x: null);
    in
    intersectAttrs feAddrSet (lib.attrByPath [ "reverses" ] {} parameters);

  # pick a suitable DNS name for client config
  frontendName =
    if feReverses != {}
    then fclib.normalizeDomain domain (head (attrValues feReverses))
    else
      if location != null
      then "${config.networking.hostName}.fe.${location}.${domain}"
      else "localhost";

  allNetworks = lib.zipAttrs (lib.catAttrs "networks" (attrValues interfaces));

  extraroutes = lib.attrByPath [ "extraroutes" ] [] accessNets;

  pushRoutes4 =
    lib.concatMapStringsSep "\n"
      (cidr: "push \"route ${decomposeCIDR cidr}\"")
      ((filter fclib.isIp4
        (attrNames allNetworks ++ extraroutes)) ++ [extnet.vxlan4]);

  pushRoutes6 =
    lib.concatMapStringsSep "\n"
      (cidr: "push \"route-ipv6 ${cidr}\"")
      ((filter fclib.isIp6
        (attrNames allNetworks ++ extraroutes)) ++ [extnet.vxlan6]);

  # Caution: we also deliver FE addresses here, so these should be included in
  # the pushed routes.
  pushNameservers = lib.concatMapStringsSep "\n"
    (a: "push \"dhcp-option DNS ${a}\"")
    (lib.attrByPath [ (toString location) ] "" cfg.static.nameservers);

  #
  # management & monitoring
  #
  mgmPort = "11194";

  mgmPsk = builtins.hashString "md5" ("OpenVPN@" + config.networking.hostName);

  checkOpenVPN = pkgs.writeScript "check_openvpn" ''
    #!${pkgs.expect}/bin/expect -f
    set timeout 20

    puts "OpenVPN: checking management interface"
    spawn -noecho ${pkgs.netcat}/bin/nc localhost ${mgmPort}

    exit -onexit {
      puts "OpenVPN CRITICAL"
      exit 2
    }

    expect {
      "PASSWORD:" {
        send "${mgmPsk}\n"
      } timeout {
        puts "OpenVPN UNKNOWN - Timeout"
        exit -onexit { }
        exit 3
      }
    }

    sleep .1

    expect "INFO:OpenVPN Management Interface" {
      send "state\n"
    }

    sleep .1

    expect "CONNECTED,SUCCESS" {
      send "quit\n"
      puts "OpenVPN OK"
      exit -onexit { }
      exit 0
    }
  '';

  #
  # server
  #
  accessNets = (fromJSON
    (fclib.configFromFile /etc/local/openvpn/networks.json defaultAccessNets));

  serverAddrs = ''
    server ${decomposeCIDR accessNets.ipv4}
    server-ipv6 ${accessNets.ipv6}
  '';

  proto = lib.attrByPath [ "proto" ] "udp6" accessNets;

  serverConfig = ''
    # OpenVPN server config for ${frontendName}
    ${serverAddrs}

    port 1194
    proto ${proto}
    dev tun
    multihome

    persist-key
    persist-tun
    duplicate-cn
    ca ${pki.caCrt}
    cert ${pki.serverCrt}
    key ${pki.serverKey}
    dh ${pki.dh}
    tls-auth ${pki.ta} 0

    keepalive 10 120
    plugin ${openvpn}/lib/openvpn/plugins/openvpn-plugin-auth-pam.so openvpn
    management localhost ${mgmPort} ${pkgs.writeText "openvpn-mgm-psk" mgmPsk}

    comp-lzo
    user nobody
    group nogroup

    push "redirect-private"
    ${pushRoutes4}
    ${pushRoutes6}
    push "dhcp-option DOMAIN ${domain}"
    push "dhcp-option DOMAIN fcio.net"
    ${pushNameservers}
  '';

  #
  # client config
  #
  ovpnTemplate = pkgs.writeText "client.ovpn-template" ''
    #viscosity name ${frontendName}

    client
    dev tun

    proto ${lib.removeSuffix "6" proto}
    #proto ${proto}
    remote ${frontendName}
    nobind
    persist-key
    persist-tun
    comp-lzo
    verb 3
    remote-cert-tls server
    auth-user-pass

    ca [inline]
    cert [inline]
    key [inline]
    tls-auth [inline] 1

    <ca>
    @caCrt@
    </ca>

    <cert>
    @clientCrt@
    </cert>

    <key>
    @clientKey@
    </key>

    <tls-auth>
    @ta@
    </tls-auth>
  '';

  # Provide additional rules for VxLAN gateways. We need to mix it up here since
  # everything should go into the same FW ruleset.
  srvRG = if lib.hasAttrByPath [ "enc_addresses" "srv" ] cfg
    then map (x: fclib.stripNetmask x.ip) cfg.enc_addresses.srv
    else [];

  dontMasqueradeSrvRG = lib.concatMapStringsSep "\n"
    (addr:
      let
        ipt = fclib.iptables addr;
        src = if fclib.isIp4 addr then extnet.vxlan4 else extnet.vxlan6;
      in
      "${ipt} -t nat -A openvpn -s ${src} -d ${addr} -j RETURN")
    srvRG;

in
{
  options = {
    flyingcircus.roles.openvpn.enable = lib.mkEnableOption { };
  };

  config = lib.mkIf cfg.roles.openvpn.enable {

    environment.systemPackages = [ pkgs.easyrsa3 ];

    environment.etc = {
      "local/openvpn/${frontendName}.ovpn".source = ovpn;
      "local/openvpn/networks.json.example".text = defaultAccessNets;
      "local/openvpn/README.txt".text = readFile ./README.openvpn;
    };

    flyingcircus.services.sensu-client.checks =
    {
      openvpn_port = {
        notification = "OpenVPN management interface";
        command = toString checkOpenVPN;
        interval = 300;
      };
    };

    networking.firewall =
    assert accessNets.ipv4 != extnet.vxlan4;
    assert accessNets.ipv6 != extnet.vxlan6;
    {
      allowedUDPPorts = [ 1194 ];
      allowedTCPPorts = [ 1194 ];
      extraCommands = ''
        ip46tables -t nat -N openvpn || true
        ip46tables -t nat -F openvpn
        ${dontMasqueradeSrvRG}
        iptables -t nat -A openvpn -s ${accessNets.ipv4} -d ${extnet.vxlan4} -j RETURN
        ip6tables -t nat -A openvpn -s ${accessNets.ipv6} -d ${extnet.vxlan6} -j RETURN
        iptables -t nat -A openvpn -s ${extnet.vxlan4} \! -d ${extnet.vxlan4} -j MASQUERADE
        ip6tables -t nat -A openvpn -s ${extnet.vxlan6} \! -d ${extnet.vxlan6} -j MASQUERADE
        iptables -t nat -A openvpn -s ${accessNets.ipv4} \! -d ${accessNets.ipv4} -j MASQUERADE
        ip6tables -t nat -A openvpn -s ${accessNets.ipv6} \! -d ${accessNets.ipv6} -j MASQUERADE

        ip46tables -t nat -D POSTROUTING -j openvpn || true
        ip46tables -t nat -A POSTROUTING -j openvpn
      '';
      extraStopCommands = ''
        ip46tables -t nat -D POSTROUTING -j openvpn || true
        ip46tables -t nat -F openvpn || true
        ip46tables -t nat -X openvpn || true
      '';
    };

    security.pam.services.openvpn.text = ''
      auth    required        pam_unix.so    shadow    nodelay
      account required        pam_unix.so
    '';

    services.dnsmasq = {
      enable = true;
      extraConfig = lib.mkOverride 500 ''
        domain-needed
        # interface=ethfe
      '';
    };

    services.openvpn.servers.access.config = serverConfig;

    system.activationScripts.openvpn-pki =
      lib.stringAfter [] ''
        ${pki}/generate-pki
        source ${pkgs.stdenv}/setup
        substitute ${ovpnTemplate} ${ovpn} \
          --subst-var-by caCrt "$(< ${pki.caCrt} )" \
          --subst-var-by clientCrt "$(< ${pki.clientCrt} )" \
          --subst-var-by clientKey "$(< ${pki.clientKey} )" \
          --subst-var-by ta "$(< ${pki.ta} )"
      '';

  };
}
