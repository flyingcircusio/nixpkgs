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

  get_json = path: default:
    if builtins.pathExists path
    then builtins.fromJSON (builtins.readFile path)
    else default;

  enc =
    get_json cfg.enc_path
    (get_json /etc/nixos/enc.json {});

  enc_addresses.srv = get_json cfg.enc_addresses_path.srv [];
  enc_addresses.fe = get_json cfg.enc_addresses_path.fe [];

  enc_services = get_json cfg.enc_services_path [];

  enc_service_clients = get_json cfg.enc_service_clients_path [];

  system_state = get_json cfg.system_state_path {};

in
{

  imports = [
    ./firewall
    ./logrotate
    ./network.nix
    ./packages.nix
    ./sensu-client.nix
    ./ssl/certificate.nix
    ./ssl/dhparams.nix
    ./systemd.nix
    ./user.nix
    ../services/vxlan-client.nix
  ];

  options = {

    flyingcircus.enc = mkOption {
      default = null;
      type = types.nullOr types.attrs;
      description = "Data from the external node classifier.";
    };

    flyingcircus.load_enc = mkOption {
      default = true;
      type = types.bool;
      description = "Automatically load ENC data?";
    };

    flyingcircus.enc_path = mkOption {
      default = "/etc/nixos/enc.json";
      type = types.string;
      description = "Where to find the ENC json file.";
    };

    flyingcircus.enc_addresses.srv = mkOption {
      default = enc_addresses.srv;
      type = types.listOf types.attrs;
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
      type = types.path;
      description = "Where to find the address list json file.";
    };

    flyingcircus.enc_addresses.fe = mkOption {
      default = enc_addresses.fe;
      type = types.listOf types.attrs;
      description = "List of addresses of machines in the neighbourhood.";
      example = [ {
        ip = "2a02:238:f030:1c3::104c/64";
        mac = "02:00:00:03:11:b1";
        name = "test03";
        rg = "test";
        rg_parent = "";
        ring = 1;
        vlan = "fe";
      } ];
    };

    flyingcircus.enc_addresses_path.fe = mkOption {
      default = /etc/nixos/addresses_fe.json;
      type = types.path;
      description = "Where to find the address list json file.";
    };

    flyingcircus.system_state = mkOption {
      default = {};
      type = types.attrs;
      description = "The current system state as put out by fc-manage";
    };

    flyingcircus.system_state_path = mkOption {
      default = /etc/nixos/system_state.json;
      type = types.path;
      description = "Where to find the system state json file.";
    };

    flyingcircus.enc_services = mkOption {
      default = [];
      type = types.listOf types.attrs;
      description = "Services in the environment as provided by the ENC.";
    };

    flyingcircus.enc_services_path = mkOption {
      default = /etc/nixos/services.json;
      type = types.path;
      description = "Where to find the ENC services json file.";
    };

    flyingcircus.enc_service_clients = mkOption {
      default = [];
      type = types.listOf types.attrs;
      description = "Service clients in the environment as provided by the ENC.";
    };

    flyingcircus.enc_service_clients_path = mkOption {
      default = /etc/nixos/service_clients.json;
      type = types.path;
      description = "Where to find the ENC service clients json file.";
    };

  };

  config = {

    nix.binaryCachePublicKeys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "flyingcircus.io-1:Rr9CwiPv8cdVf3EQu633IOTb6iJKnWbVfCC8x8gVz2o="
    ];

    nix.binaryCaches = [
      https://cache.nixos.org
      https://hydra.flyingcircus.io
    ];

    flyingcircus.enc = lib.optionalAttrs cfg.load_enc enc;
    flyingcircus.enc_services = enc_services;
    flyingcircus.enc_service_clients = enc_service_clients;
    flyingcircus.system_state = system_state;

    users.motd = ''
        Welcome to the Flying Circus!

        Support:   support@flyingcircus.io or +49 345 219401-0
        Status:    http://status.flyingcircus.io/
        Docs:      https://flyingcircus.io/doc/
        Release:   ${config.system.nixosVersion}

    '' +
    (lib.optionalString
      (enc ? name &&
        (lib.hasAttrByPath [ "parameters" "location" ] enc) &&
        (lib.hasAttrByPath [ "parameters" "environment" ] enc) &&
        (lib.hasAttrByPath [ "parameters" "service_description" ] enc))
      ''
        Hostname:  ${enc.name}    Environment: ${enc.parameters.environment}    Location:  ${enc.parameters.location}
        Services:  ${enc.parameters.service_description}

      '');

    services.cron.enable = true;
    sound.enable = false;
    fonts.fontconfig.enable = true;
    programs.zsh.enable = true;

    environment.pathsToLink = [ "/include" ];
    environment.shellInit = ''
     # help pip to find libz.so when building lxml
     export LIBRARY_PATH=/var/run/current-system/sw/lib
     # help dynamic loading like python-magic to find it's libraries
     export LD_LIBRARY_PATH=$LIBRARY_PATH
     # ditto for header files, e.g. sqlite
     export C_INCLUDE_PATH=/var/run/current-system/sw/include:/var/run/current-system/sw/include/sasl
    '';
    environment.interactiveShellInit = ''
      TMOUT=43200
    '';

    boot.kernelPackages = pkgs.linuxPackages_4_4;

    environment.etc = (
      lib.optionalAttrs (lib.hasAttrByPath ["parameters" "directory_secret"] cfg.enc)
      { "directory.secret".text = cfg.enc.parameters.directory_secret;
        "directory.secret".mode = "0600";}) //
      { "nixos/configuration.nix".text = pkgs.lib.readFile ../files/etc_nixos_configuration.nix; };

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

    systemd.services.nix-collect-garbage = {
      serviceConfig = { Type = "oneshot"; };
      script = "nix-collect-garbage --delete-older-than 30d";
      path = [ pkgs.nix ];
      # XXX reenable until #23752 is solved
      enable = false;
      # startAt =
      #   let
      #     minute = fclib.mod (lib.attrByPath [ "parameters" "id" ] 0 enc) 60;
      #   in
      #   "05:${toString minute}";
    };

    time.timeZone =
      if lib.hasAttrByPath ["parameters" "timezone"] cfg.enc
      then cfg.enc.parameters.timezone
      else "UTC";
  };

}
