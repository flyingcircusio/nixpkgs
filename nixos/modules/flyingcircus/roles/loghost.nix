{ config, lib, pkgs, ... }: with lib;
let
  fclib = import ../lib;
  listenOn = head (fclib.listenAddresses config "ethsrv");

  loghostService = lib.findFirst
    (s: s.service == "loghost-server")
    null
    config.flyingcircus.enc_services;

  passwordSecret = fclib.generatePassword { serviceName = "graylog"; length = 96; };
  rootPasswordSha2 = builtins.elemAt (fclib.generatePasswordHash { serviceName = "graylog-webui"; length = 32; }) 1;

in
{

  options = {

    flyingcircus.roles.loghost = {

      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable the Flying Circus graylog server role.";
      };

    };

  };

  config = mkMerge [

    (mkIf config.flyingcircus.roles.loghost.enable {

      networking.firewall.extraCommands = ''
        # Allow access to installed nginx on FE interface.
        ip46tables -A nixos-fw -p tcp --dport 9000 -i ethsrv -j nixos-fw-accept
      '';
      services.graylog = {
        inherit passwordSecret rootPasswordSha2;
      	enable = true;
  	    elasticsearchClusterName = "graylog";
        elasticsearchDiscoveryZenPingUnicastHosts =
          "${config.networking.hostName}.${config.networking.domain}:9300";
  	    extraConfig = ''
          # IPv6 would be nice, too :/
          web_listen_uri http://${listenOn}:9000/tools/${config.flyingcircus.enc.name}/graylog
          rest_listen_uri http://${listenOn}:9000/tools/${config.flyingcircus.enc.name}/graylog/api
          trusted_proxies 195.62.125.243/32, 195.62.125.11/32, 172.22.49.56/32
  	    '';
    	};

      flyingcircus.roles.mongodb.enable = true;
    	flyingcircus.roles.elasticsearch = {
        enable = true;
        dataDir = "/var/lib/elasticsearch";
        clusterName = "graylog";
        heapDivisor = 3;
        esNodes = ["${config.networking.hostName}.${config.networking.domain}:9350"];
      };
    })
    (mkIf (loghostService != null) {
      services.rsyslogd.extraConfig = ''
        *.* @${loghostService.address}:5140;RSYSLOG_SyslogProtocol23Format
      '';
    })];
}
