{ config, pkgs, lib, ... }:

with pkgs;
with lib;

let

  cfg = config.flyingcircus.services.sensu-client;

  fclib = import ../../lib;

  cores = fclib.current_cores config 1;

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
      "_comment":
        ["This is a comment to help restarting sensu when necessary.",
         "Active Groups: ${toString config.users.extraUsers.sensuclient.extraGroups}"],
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
      timeout = mkOption {
        type = types.nullOr types.int;
        default = null;
        description = "The timeout when the client should abort the check and consider it failed.";
      };
      ttl = mkOption {
        type = types.nullOr types.int;
        default = null;
        description = "The time after which a check result should be considered stale and cause an event.";
      };
      standalone = mkOption {
        type = types.bool;
        default = true;
        description = "Whether to schedule this check autonomously on the client.";
      };
      warnIsCritical = mkOption {
        type = types.bool;
        default = false;
        description = "Whether a warning of this check should be escalated to critical by our status page.";
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
      loglevel = mkOption {
        type = types.str;
        default = "warn";
        description = ''
          The level of logging.
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
          default = 5000;
        };
        critical = mkOption {
          type = types.int;
          description = ''
            Set the critical limit for connections on this host.
          '';
          default = 6000;
        };
      };
      expectedLoad = {
        warning = mkOption {
          type = types.str;
          default = "${toString (cores * 8)},${toString (cores * 5)},${toString (cores * 2)}";
          description = ''Limit of load thresholds before warning.'';
        };
        critical = mkOption {
          type = types.str;
          default = "${toString (cores * 10)},${toString (cores * 8)},${toString (cores * 3)}";
          description = ''Limit of load thresholds before reaching critical.'';
        };
      };
    };
  };

  config = mkIf cfg.enable {
    system.activationScripts.sensu-client = ''
      install -d -o sensuclient -g service -m 775 /etc/local/sensu-client
      install -d -o sensuclient -g service -m 775 /var/tmp/sensu
      install -d /run/current-config/sensu ${local_sensu_configuration}
      rm -rf /run/current-config/sensu/*
      (cat ${client_json} | ${pkgs.perlPackages.JSONPP}/bin/json_pp > /run/current-config/sensu/client.json) || ln -sf  ${client_json} /run/current-config/sensu/client.json
      ln -fs ${local_sensu_configuration} /run/current-config/sensu/local.d
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
      # Allow sensuclient to interact with services, adm stuff and the journal.
      # This especially helps to check supervisor with a group-writable
      # socket:
      extraGroups = [ "service" "adm" "systemd-journal" ];
    };

    # needs to be adjusted, when we fix issue https://github.com/flyingcircusio/vulnix/issues/13
    security.sudo.extraConfig = ''
       # Sensu sudo rules
       Cmnd_Alias VULNIX_DIR = ${pkgs.coreutils}/bin/install -o sensuclient -g sensuclient -d /var/cache/vulnix
       Cmnd_Alias VULNIX_CMD = ${pkgs.vulnix}/bin/vulnix

       %sensuclient ALL=(root) VULNIX_DIR
       %sensuclient ALL=(root) VULNIX_CMD
   '';

    systemd.services.sensu-client = {
      wantedBy = [ "multi-user.target" ];
      path = [
        pkgs.bash
        pkgs.coreutils
        pkgs.glibc
        pkgs.lm_sensors
        pkgs.nagiosPluginsOfficial
        pkgs.sensu
      ];
      serviceConfig = {
        User = "sensuclient";
        ExecStart = ''
          ${sensu}/bin/sensu-client -L ${cfg.loglevel} -c ${client_json} ${local_sensu_configuration}
        '';
        Restart = "always";
        RestartSec = "5s";
      };
      environment = {
        EMBEDDED_RUBY = "true";
        LANG = "en_US.utf8";
      };
      preStart = ''
        /var/setuid-wrappers/sudo install -o sensuclient -g sensuclient \
          -d /var/cache/vulnix
      '';
    };

    flyingcircus.services.sensu-client.checks = {
      load = {
        notification = "Load is too high";
        command =  "check_load -r -w ${cfg.expectedLoad.warning} -c ${cfg.expectedLoad.critical}";
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
      systemd_units = {
        notification = "SystemD has failed units";
        command = "check-failed-units.rb -m logrotate.service";
      };
      disk = {
        notification = "Disk usage too high";
        command = "${pkgs.fcsensuplugins}/bin/check_disk -v -w 90 -c 95";
        interval = 300;
      };
      writable = {
        notification = "Disks are writable";
        command = "${pkgs.fcsensuplugins}/bin/check_writable /tmp/.sensu_writable /var/tmp/sensu/.sensu_writable";
        interval = 60;
        ttl = 120;
        warnIsCritical = true;
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
        command = "${pkgs.fcsensuplugins}/bin/check_journal -v https://bitbucket.org/flyingcircus/fc-logcheck-config/raw/tip/nixos-journal.yaml";
        interval = 600;
      };
      journal_file = {
        notification = "Journal file too small. (last 12h)";
        command = "${pkgs.fcsensuplugins}/bin/check_journal_file";
        interval = 12 * 3600;
      };

      vulnix = {
        notification = "Security vulnerabilities in the last 6h";
        command =
        let
          whitelist = https://raw.githubusercontent.com/flyingcircusio/vulnix.whitelist/master/fcio-whitelist.yaml;
        in
          "NIX_REMOTE=daemon nice /var/setuid-wrappers/sudo " +
          "${pkgs.vulnix}/bin/vulnix --system --cache-dir /var/cache/vulnix " +
          "-w ${whitelist}";
        interval = 6 * 3600;
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
