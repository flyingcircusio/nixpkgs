# Access external networks. This includes VxLAN tunnels to Kamp DHP and
# OpenVPN.

# Assumes that the address ranges for network extensions are within
# - 10.0.0.0/8
# - fde6:1c0f:70c3::/48

{ config, lib, pkgs, ... }:

let
  cfg = config.flyingcircus;
  gw = lib.findFirst
    (s: s.service == "external_net-gateway") null cfg.enc_services;
  fqdn = "${cfg.enc.name}.${config.networking.domain}";
in

{
  options = {
    flyingcircus.roles.external_net_client = {
      enable = lib.mkOption {
        description = "Access external networks via external_net gateway";
        type = lib.types.bool;
        default = (gw != null) && (gw.address != fqdn);
      };
    };
  };

  config = lib.mkIf cfg.roles.external_net_client.enable (
    let
      awk = "${pkgs.gawk}/bin/awk";
      getent = "${pkgs.glibc}/bin/getent";
      ip = "${pkgs.iproute}/bin/ip";
    in
    {
      networking.firewall.extraCommands = ''
        # access from external networks gateway
        iptables -A nixos-fw -i ethsrv -s 10.0.0.0/8 -j nixos-fw-accept
        ip6tables -A nixos-fw -i ethsrv -s fde6:1c0f:70c3::/48 -j nixos-fw-accept
      '';

      systemd.services."network-external-routing" = {
        description = "Custom routing rules for external networks";
        after = [ "network-local-commands.service" ];
        requires = [ "network-local-commands.service" ];
        wantedBy = [ "network.target" ];
        bindsTo = [ "sys-subsystem-net-devices-ethsrv.device" ];

        serviceConfig = {
          Type = "oneshot";
          ExecStart = pkgs.writeScript "network-external-routing-start" ''
            #! ${pkgs.stdenv.shell} -e
            echo "Adding routes via external network gateway ${gw.address}"
            gw4=$(${getent} ahostsv4 ${gw.address} | ${awk} 'NR==1 {print $1}')
            gw6=$(${getent} ahostsv6 ${gw.address} | ${awk} 'NR==1 {print $1}')
            ${ip} -4 rule add to 10.0.0.0/8 table srv priority 500
            ${ip} -4 rule add from 10.0.0.0/8 table srv priority 500
            ${ip} -4 route add 10.0.0.0/8 via $gw4 dev ethsrv table srv
          '';
          ExecStop = pkgs.writeScript "network-external-routing-stop" ''
            #! ${pkgs.stdenv.shell}
            echo "Removing routes via external network gateway ${gw.address}"
            ${ip} -4 route del 10.0.0.0/8 table srv
            ${ip} -4 rule del from 10.0.0.0/8 table srv
            ${ip} -4 rule del to 10.0.0.0/8 table srv
          '';
          RemainAfterExit = true;
        };
      };
    }
  );
}
