{ config, pkgs, lib, ... }:

with lib;

let

  cfg = config.flyingcircus.services.sensu-server;

  sensu_clients = filter
    (x: x.service == "sensuserver-server")
    config.flyingcircus.enc_service_clients;

  server_password = (lib.findSingle
    (x: x.node == "${config.networking.hostName}.gocept.net")
    { password = ""; } { password = ""; } sensu_clients).password;

  directory_handler = "${pkgs.fcmanage}/bin/fc-monitor --enc ${config.flyingcircus.enc_path} handle-result";

  sensu_server_json = pkgs.writeText "sensu-server.json"
    ''
    {
      "rabbitmq": {
        "host": "${config.networking.hostName}.gocept.net",
        "user": "sensu-server",
        "password": "${server_password}",
        "vhost": "/sensu"
      },
      "handlers": {
        "directory": {
          "type": "pipe",
          "command": "/var/setuid-wrappers/sudo ${directory_handler}"
        },
        "default": {
          "handlers": [],
          "type": "set"
        }
      }

    ${cfg.config}

    }
    '';

in {

  options = {

    flyingcircus.services.sensu-server = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Enable the Sensu monitoring server daemon.
        '';
      };
      config = mkOption {
        type = types.lines;
        description = ''
          Contents of the sensu configuration file.
        '';
        default = "";
      };
      extraOpts = mkOption {
        type = with types; listOf str;
        default = [];
        description = ''
          Extra options used when launching sensu.
        '';
      };
    };
  };

  config = mkIf cfg.enable {

    # Dependencies

    services.rabbitmq.enable = true;
    services.rabbitmq.listenAddress = "::";
    services.rabbitmq.plugins = [ "rabbitmq_management" ];
    services.redis.enable = true;
    services.postfix.enable = true;

    ##############
    # Sensu Server

    networking.firewall.extraCommands = ''
      ip46tables -A nixos-fw -i ethsrv -p tcp --dport 5672 -j nixos-fw-accept
    '';

    users.extraGroups.sensuserver.gid = config.ids.gids.sensuserver;

    users.extraUsers.sensuserver = {
      description = "sensu server daemon user";
      uid = config.ids.uids.sensuserver;
      group = "sensuserver";
    };

    security.sudo.extraConfig = ''
      Cmnd_Alias  SENSU_DIRECTORY_HANDLER = ${directory_handler}
      sensuserver ALL=(root) SENSU_DIRECTORY_HANDLER
    '';

    systemd.services.prepare-rabbitmq-for-sensu = {
      description = "Prepare rabbitmq for sensu-server.";
      requires = [ "rabbitmq.service" ];
      after = ["rabbitmq.service" ];
      path = [ pkgs.rabbitmq_server ];
      serviceConfig = {
        Type = "oneshot";
        User = "rabbitmq";
      };
      script = let
        curl = ''
          ${pkgs.curl}/bin/curl -s \
             -u "sensu-server:${server_password}" \
             -H "content-type:application/json" \
        '';
        api = "http://localhost:15672/api";
        clients = (lib.concatMapStrings (
          client:
            let client_name = builtins.head (lib.splitString "." client.node);
            password_body = {
              password = client.password;
              tags = "";
            };
            # Permission settings required for sensu
            # exchange.declare -> configure "keepalives"
            # queue.declare -> configure "node-*"
            # queue.bind -> write "node-*"
            permissions_body = {
              scope = "client";
              configure = "^((default|results|keepalives)$)|${client_name}-.*";
              write = "^((keepalives|results)$)|${client_name}-.*";
              read = "^(default$)|${client_name}-.*";
            };
            in ''
              # Configure user and permissions for ${client.node}:
              ${curl} -XPUT \
                -d'${builtins.toJSON password_body}' \
                ${api}/users/${client.node}
              # Permission for clients in order: conf, write, read
              # exchange.declare -> configure "keepalives"
              # queue.declare -> configure "node-*"
              # queue.bind -> write "node-*"
              ${curl} -XPUT \
                -d'${builtins.toJSON permissions_body}' \
                ${api}/permissions/%2Fsensu/${client.node}
              # Delete wrongly set permission. Can go away after a release.
              ${curl} -XDELETE \
                ${api}/permissions/sensu/${client.node} \
                | ${pkgs.gnugrep}/bin/grep -v "Object Not Found" || true
              '')
          sensu_clients);
      in
      ''
        set -e

        ${curl} -f ${api}/overview >/dev/null || (
          rabbitmqctl start_app || sleep 5
          rabbitmqctl add_user sensu-server ${server_password} || true
          rabbitmqctl set_user_tags sensu-server administrator
          rabbitmqctl change_password sensu-server ${server_password}
          rabbitmqctl set_permissions -p /sensu sensu-server ".*" ".*" ".*"
        )

        ${curl} -XDELETE ${api}/users/guest >/dev/null
        ${curl} -XPUT ${api}/vhosts/%2Fsensu

        ${clients}
      '';
    };

    systemd.timers.sensu-users = {
      description = "Timer for setting up sensu users in rabbitmq";
      after = [ "network.target" ];
      wantedBy = [ "timers.target" ];
      timerConfig = {
        Unit = "prepare-rabbitmq-for-sensu.service";
        OnUnitActiveSec = "10m";
      };
    };

    systemd.services.sensu-server = {
      wantedBy = [ "multi-user.target" ];
      path = [ pkgs.sensu pkgs.openssl pkgs.bash pkgs.mailutils ];
      requires = [
        "rabbitmq.service"
        "redis.service" ];
      serviceConfig = {
        User = "sensuserver";
        ExecStart = "${pkgs.sensu}/bin/sensu-server -c ${sensu_server_json} " +
          "--log_level warn";
        Restart = "always";
        RestartSec = "5s";
      };
      environment = { EMBEDDED_RUBY = "false"; };

      # rabbitmq needs some time to start up. The wait for pid
      # in the default service config doesn't really seem to help :(
      preStart = ''
          sleep 5
      '';
    };

  };

}
