{ config, pkgs, lib, ... }:

with pkgs;
with lib;

let

  cfg = config.flyingcircus.services.sensu-client;

  check_timer = writeScript "check-timer.sh" ''
    #!${pkgs.bash}/bin/bash
    timer=$1
    output=$(systemctl status $1.timer)
    result=$?
    echo "$output" | iconv -c -f utf-8 -t ascii
    exit $(( result != 0 ? 2 : 0 ))
    '';

  local_sensu_configuration =
    if  pathExists /etc/local/sensu-client
    then "-d ${/etc/local/sensu-client}"
    else "";

  client_json = writeText "client.json" ''
    {
      "client": {
        "name": "${config.networking.hostName}",
        "address": "${config.networking.hostName}.gocept.net",
        "subscriptions": ["default"],
        "signature": "${cfg.password}"
      },
      "rabbitmq": {
        "host": "${cfg.server}",
        "user": "${config.networking.hostName}.gocept.net",
        "password": "${cfg.password}",
        "vhost": "/sensu"
      },
      "checks": ${builtins.toJSON
        (lib.mapAttrs (name: value: filterAttrs (name: value: name != "_module") value) cfg.checks)}
    }
  '';

  checkOptions = { name, config, ... }: {

    options = {
      notification = mkOption {
        type = types.str;
        description = "The notification on events.";
      };
      command = mkOption {
        type = types.str;
        description = "The command to execute as the check.";
      };
      interval = mkOption {
        type = types.int;
        default = 60;
        description = "The interval (in seconds) how often this check should be performed.";
      };
      standalone = mkOption {
        type = types.bool;
        default = true;
        description = "Whether to schedule this check autonomously on the client.";
      };
    };
  };


in {

  options = {

    flyingcircus.services.sensu-client = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Enable the Sensu monitoring client daemon.
        '';
      };
      server = mkOption {
        type = types.str;
        description = ''
          The address of the server (RabbitMQ) to connect to.
        '';
      };
      password = mkOption {
        type = types.str;
        description = ''
          The password to connect with to server (RabbitMQ).
        '';
      };
      config = mkOption {
        type = types.lines;
        description = ''
          Contents of the sensu client configuration file.
        '';
      };
      checks = mkOption {
        default = {};
        type = types.attrsOf types.optionSet;
        options = [ checkOptions ];
        description = ''
          Checks that should be run by this client.
          Defined as attribute sets that conform to the JSON structure
          defined by Sensu:
          https://sensuapp.org/docs/latest/checks
        '';
      };
      extraOpts = mkOption {
        type = with types; listOf str;
        default = [];
        description = ''
          Extra options used when launching sensu.
        '';
      };
      expectedConnections = {
        warning = mkOption {
          type = types.int;
          description = ''
            Set the warning limit for connections on this host.
          '';
          default = 500;
        };
        critical = mkOption {
          type = types.int;
          description = ''
            Set the critical limit for connections on this host.
          '';
          default = 1000;
        };
      };
    };
  };

  config = mkIf cfg.enable {
    ids.gids.sensuclient = 207;
    ids.uids.sensuclient = 207;

    system.activationScripts.sensu-client = ''
      install -d -o sensuclient -g service -m 775 /etc/local/sensu-client
    '';
    environment.etc."local/sensu-client/README.txt".text = ''
      Put local sensu checks here.

      This directory is passed to sensu as additional config directory. You
      can add .json files for your checks.

      Example:

        {
         "checks" : {
            "my-custom-check" : {
               "notification" : "custom check broken",
               "command" : "/srv/user/bin/nagios_compatible_check",
               "interval": 60,
               "standalone" : true
            },
            "my-other-custom-check" : {
               "notification" : "custom check broken",
               "command" : "/srv/user/bin/nagios_compatible_other_check",
               "interval": 600,
               "standalone" : true
            }
          }
        }
    '';

    users.extraGroups.sensuclient.gid = config.ids.gids.sensuclient;

    users.extraUsers.sensuclient = {
      description = "sensu client daemon user";
      uid = config.ids.uids.sensuclient;
      group = "sensuclient";
      # Allow sensuclient to interact with services. This especially helps to
      # check supervisor with a group-writable socket:
      extraGroups = ["service"];
    };

    # needs to be adjusted, when we fix issue https://github.com/flyingcircusio/vulnix/issues/13
    security.sudo.extraConfig = ''
       # Sensu sudo rules
       Cmnd_Alias VULNIX_DIR = ${pkgs.coreutils}/bin/mkdir -p /var/cache/vulnix, \
              ${pkgs.coreutils}/bin/chown sensuclient\:sensuclient /var/cache/vulnix
       Cmnd_Alias VULNIX_CMD = ${pkgs.vulnix}/bin/vulnix

       %sensuclient ALL=(root) VULNIX_DIR
       %sensuclient ALL=(root) VULNIX_CMD

   '';
    systemd.services.sensu-client = {
      wantedBy = [ "multi-user.target" ];
      path = [ pkgs.sensu pkgs.glibc pkgs.nagiosPluginsOfficial pkgs.bash pkgs.lm_sensors ];
      serviceConfig = {
        User = "sensuclient";
        ExecStart = "${sensu}/bin/sensu-client -L warn -c ${client_json} ${local_sensu_configuration}";
        Restart = "always";
        RestartSec = "5s";
      };
      preStart= ''
          /var/setuid-wrappers/sudo ${pkgs.coreutils}/bin/mkdir -p /var/cache/vulnix && \
          /var/setuid-wrappers/sudo ${pkgs.coreutils}/bin/chown sensuclient:sensuclient /var/cache/vulnix
        '';
      environment = { EMBEDDED_RUBY = "true"; };
    };

    flyingcircus.services.sensu-client.checks = {
      load = {
        notification = "Load is too high";
        command =  "check_load -r -w 2.0,1.3,0.9 -c 4,3,2";
        interval = 10;
      };
      swap = {
        notification = "Swap is running low";
        command = "check_swap -w 20% -c 10%";
        interval = 300;
      };
      ssh = {
        notification = "SSH server is not responding properly";
        command = "check_ssh localhost";
        interval = 300;
      };
      ntp_time = {
        notification = "Clock is skewed";
        command = "check_ntp_time -H 0.de.pool.ntp.org";
        interval = 300;
      };
      internet_uplink_ipv4 = {
        notification = "Internet (Google) is not available";
        command = "check_ping  -w 100,5% -c 200,10% -H google.com  -4";
      };
      internet_uplink_ipv6 = {
        notification = "Internet (Google) is not available";
        command = "check_ping  -w 100,5% -c 200,10% -H google.com  -6";
      };
      uptime = {
        notification = "Host was down";
        command = "check_uptime";
        interval = 300;
      };
      users = {
        notification = "Too many users logged in";
        command = "check_users -w 5 -c 10";
        interval = 300;
      };
      systemd_units = {
        notification = "SystemD has failed units";
        command = "check-failed-units.rb";
      };
      disk = {
        notification = "Disk usage too high";
        command = "${pkgs.fcsensuplugins}/bin/check_disk -v -w 90 -c 95";
        interval = 300;
      };
      entropy = {
        notification = "Too little entropy available";
        command = "check-entropy.rb -w 120 -c 60";
      };
      local_resolver = {
        notification = "Local resolver not functional";
        command = "check-dns.rb -d ${config.networking.hostName}.gocept.net";
      };
      journal = {
        notification = "Journal errors in the last 10 minutes";
        command = ''
          ${pkgs.fcsensuplugins}/bin/check_journal -v ${./check_journal.yaml}
        '';
        interval = 600;
      };
      vulnix = {
        notification = "Security vulnerabilities in the last 6h";
        command = "NIX_REMOTE=daemon /var/setuid-wrappers/sudo ${pkgs.vulnix}/bin/vulnix --system --cache-dir /var/cache/vulnix";
        interval = 21600;
      };
      manage = {
        notification = "The FC manage job is not enabled.";
        command = "${check_timer} fc-manage";
      };
      netstat_tcp = {
        notification = "Netstat TCP connections";
        command = "check-netstat-tcp.rb -w ${toString cfg.expectedConnections.warning} -c ${toString cfg.expectedConnections.critical}";
      };
      ethsrv_mtu = {
        notification = "ethsrv MTU @ 1500";
        command = "check-mtu.rb -i ethsrv -m 1500";
      };
      ethfe_mtu = {
        notification = "ethfe MTU @ 1500";
        command = "check-mtu.rb -i ethfe -m 1500";
      };
    };
  };

}
