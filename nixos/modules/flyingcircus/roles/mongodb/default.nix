{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.flyingcircus;
  mcfg = config.services.mongodb;
  fclib = import ../../lib;

  listen_addresses =
    fclib.listenAddresses config "lo" ++
    fclib.listenAddresses config "ethsrv";

  local_config_path = /etc/local/mongodb/mongodb.conf;

  local_config =
    if pathExists local_config_path
    then builtins.readFile  local_config_path
    else "";

  # Use a completely own version of mongodb.conf (not resorting to NixOS
  # defaults). The stock version includes a hard-coded "syslog = true"
  # statement.
  mongoCnf = pkgs.writeText "mongodb.conf" ''
    bind_ip = ${mcfg.bind_ip}
    ${optionalString mcfg.quiet "quiet = true"}
    dbpath = ${mcfg.dbpath}
    fork = true
    pidfilepath = ${mcfg.pidFile}
    ${optionalString (mcfg.replSetName != "") "replSet = ${mcfg.replSetName}"}
    ipv6 = true
    logpath = /var/log/mongodb/mongodb.log
    logappend = true
    logRotate = reopen
    ${local_config}
  '';

  mongo_check = pkgs.callPackage ./check.nix { };

in
{
  options = {

    flyingcircus.roles.mongodb = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable the Flying Circus MongoDB role.";
      };
    };

  };

  config = mkIf cfg.roles.mongodb.enable {

    environment.systemPackages = [
      pkgs.mongodb-tools
    ];

    services.mongodb.enable = true;
    services.mongodb.dbpath = "/srv/mongodb";
    services.mongodb.bind_ip = concatStringsSep "," listen_addresses;
    services.mongodb.pidFile = "/run/mongodb.pid";

    systemd.services.mongodb = {
      preStart = "echo never > /sys/kernel/mm/transparent_hugepage/defrag";
      postStop = "echo always > /sys/kernel/mm/transparent_hugepage/defrag";
      serviceConfig.LimitNOFILE = 64000;
      serviceConfig.LimitNPROC = 32000;
      serviceConfig.ExecStart = mkForce ''
        ${mcfg.package}/bin/mongod --config ${mongoCnf}
      '';
      reload = ''
        if [[ -f ${mcfg.pidFile} ]]; then
          kill -USR1 $(< ${mcfg.pidFile} )
        fi
      '';
    };

    users.users.mongodb = {
      shell = "/run/current-system/sw/bin/bash";
      home = "/srv/mongodb";
    };

    system.activationScripts.flyingcircus-mongodb =
    let
      uid = toString config.ids.uids.mongodb;
    in ''
      install -d -o ${uid} /{srv,var/log}/mongodb
      install -d -o ${uid} -g service -m 02775 /etc/local/mongodb
    '';

    security.sudo.extraConfig = ''
      # Service users may switch to the mongodb system user
      %sudo-srv ALL=(mongodb) ALL
      %service ALL=(mongodb) ALL
      %sensuclient ALL=(mongodb) ALL
    '';

    environment.etc."local/mongodb/README.txt".text = ''
      Put your local mongodb configuration into `mongodb.conf` here.
      It will be joined with the basic config.
    '';

    services.logrotate.config = ''
      /var/log/mongodb/*.log {
        nocreate
        postrotate
          systemctl reload mongodb
        endscript
      }
    '';

    flyingcircus.services.sensu-client.checks = {
      mongodb = {
        notification = "MongoDB alive";
        command = ''
          /var/setuid-wrappers/sudo -u mongodb -- \
            ${mongo_check}/bin/check_mongo -d mongodb
        '';
      };
    };

    flyingcircus.services.sensu-client.expectedConnections = {
      warning = 60000;
      critical = 63000;
    };

  };
}
