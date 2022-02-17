# Defines general platform features, like user-management, etc.
#
# This configuration is independent of infrastructure, roles,
# physical/virtual, etc.
#
# It can use parametrized options depending on the ENC or the `data` module.

{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.flyingcircus;

  fclib = import ../lib;

  enc =
    builtins.fromJSON (fclib.configFromFile
      cfg.enc_path
      (fclib.configFromFile "/etc/nixos/enc.json" "{}"));

  enc_addresses.srv = fclib.jsonFromFile cfg.enc_addresses_path.srv "[]";

  enc_services = fclib.jsonFromFile cfg.enc_services_path "[]";

  enc_service_clients = fclib.jsonFromFile cfg.enc_service_clients_path "[]";

  system_state = fclib.jsonFromFile cfg.system_state_path "{}";

  userdata = fclib.jsonFromFile cfg.userdata_path "[]";

  permissionsdata = fclib.jsonFromFile cfg.permissions_path "[]";

  admins_group_data = fclib.jsonFromFile cfg.admins_group_path "{}";

in
{

  imports = [
    ./firewall.nix
    ./garbagecollect
    ./logrotate
    ./network.nix
    ./packages.nix
    ./sensu-client.nix
    ./shell.nix
    ./ssl/certificate.nix
    ./ssl/dhparams.nix
    ./systemd.nix
    ./user.nix
    ../services/vxlan-client.nix
  ];

  options = with lib.types;
  {

    flyingcircus.enc = mkOption {
      default = null;
      type = nullOr attrs;
      description = "Data from the external node classifier.";
    };

    flyingcircus.load_enc = mkOption {
      default = true;
      type = bool;
      description = "Automatically load ENC data?";
    };

    flyingcircus.enc_path = mkOption {
      default = "/etc/nixos/enc.json";
      type = string;
      description = "Where to find the ENC json file.";
    };

    flyingcircus.enc_addresses.srv = mkOption {
      default = enc_addresses.srv;
      type = listOf attrs;
      description = "List of addresses of machines in the neighbourhood.";
      example = [ {
        ip = "2a02:238:f030:1c3::104c/64";
        mac = "02:00:00:03:11:b1";
        name = "test03";
        rg = "test";
        rg_parent = "";
        ring = 1;
        vlan = "srv";
      } ];
    };

    flyingcircus.enc_addresses_path.srv = mkOption {
      default = /etc/nixos/addresses_srv.json;
      type = path;
      description = "Where to find the address list json file.";
    };

    flyingcircus.system_state = mkOption {
      default = {};
      type = attrs;
      description = "The current system state as put out by fc-manage";
    };

    flyingcircus.system_state_path = mkOption {
      default = /etc/nixos/system_state.json;
      type = path;
      description = "Where to find the system state json file.";
    };

    flyingcircus.enc_services = mkOption {
      default = [];
      type = listOf attrs;
      description = "Services in the environment as provided by the ENC.";
    };

    flyingcircus.enc_services_path = mkOption {
      default = /etc/nixos/services.json;
      type = path;
      description = "Where to find the ENC services json file.";
    };

    flyingcircus.enc_service_clients = mkOption {
      default = [];
      type = listOf attrs;
      description = "Service clients in the environment as provided by the ENC.";
    };

    flyingcircus.enc_service_clients_path = mkOption {
      default = /etc/nixos/service_clients.json;
      type = path;
      description = "Where to find the ENC service clients json file.";
    };

    flyingcircus.userdata_path = lib.mkOption {
      default = /etc/nixos/users.json;
      type = path;
      description = ''
        Where to find the user json file.

        directory.list_users();
      '';
    };

    flyingcircus.userdata = lib.mkOption {
      default = userdata;
      type = listOf attrs;
      description = "All users local to this system.";
    };

    flyingcircus.permissions_path = lib.mkOption {
      default = /etc/nixos/permissions.json;
      type = path;
      description = ''
        Where to find the permissions json file.

        directory.list_permissions()
      '';
    };

    flyingcircus.permissionsdata = lib.mkOption {
      default = permissionsdata;
      type = listOf attrs;
      description = "All permissions known on this system.";
    };

    flyingcircus.admins_group_path = lib.mkOption {
      default = /etc/nixos/admins.json;
      type = path;
      description = ''
        Where to find the admins group json file.

        directory.lookup_resourcegroup('admins')
      '';
    };

    flyingcircus.admins_group_data = lib.mkOption {
      default = admins_group_data;
      type = attrs;
      description = "Members of ths admins group.";
    };

  };

  config = {

    nix = {
      binaryCachePublicKeys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "flyingcircus.io-1:Rr9CwiPv8cdVf3EQu633IOTb6iJKnWbVfCC8x8gVz2o="
      ];

      binaryCaches = lib.mkOverride 90 [
        "https://cache.nixos.org"
        "https://s3.whq.fcio.net/hydra"
        "https://hydra.flyingcircus.io"
      ];

      extraOptions = ''
        fallback = true
      '';
    };

    flyingcircus.enc = lib.optionalAttrs cfg.load_enc enc;
    flyingcircus.enc_services = enc_services;
    flyingcircus.enc_service_clients = enc_service_clients;
    flyingcircus.system_state = system_state;

    services.cron.enable = true;
    sound.enable = false;
    fonts.fontconfig.enable = true;

    environment.pathsToLink = [ "/include" ];
    boot.kernelPackages = pkgs.linuxPackages_4_4;
    boot.supportedFilesystems = [ "nfs4" ];

    environment.etc = (
      lib.optionalAttrs
        (lib.hasAttrByPath ["parameters" "directory_secret"] cfg.enc)
        {
          "directory.secret".text = cfg.enc.parameters.directory_secret;
          "directory.secret".mode = "0600";
        })
      // {
        "nixos/configuration.nix".text =
          lib.readFile ../files/etc_nixos_configuration.nix;
      };

    # obsolete in Nix 2.0
    nix.requireSignedBinaryCaches = false;

    services.openssh = {
      enable = true;
      challengeResponseAuthentication = false;
      passwordAuthentication = false;
    };
    services.nscd.enable = true;

    systemd.tmpfiles.rules = [
      # d instead of r to a) respect the age rule and b) allow exclusion
      # of fc-data to avoid killing the seeded ENC upon boot.
      "d /tmp 1777 root root 3d"
      "d /var/tmp 1777 root root 7d"
      "d /srv"
      "z /srv 0755 root root"
    ];

    time.timeZone =
      if lib.hasAttrByPath ["parameters" "timezone"] cfg.enc
      then cfg.enc.parameters.timezone
      else "UTC";
  };

}
