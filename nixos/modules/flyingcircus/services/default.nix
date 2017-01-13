{ ... }:

{
  imports =
    [
     ./fcmanage.nix
     ./graylog.nix
     ./influxdb011.nix
     ./percona.nix
     ./powerdns.nix
     ./rsyslog.nix
     ./sensu/api.nix
     ./sensu/client.nix
     ./sensu/server.nix
     ./sensu/uchiwa.nix
    ];
}
