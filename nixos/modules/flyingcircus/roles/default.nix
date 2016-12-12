{ config, lib, pkgs, ... }:

let

  cfg = config.flyingcircus;

  optionalAttr = set: name: default:
    if builtins.hasAttr name set then set.${name} else default;

  enc_roles = optionalAttr cfg.enc "roles" [];

in

{

  imports =
    [
     ./compat.nix
     ./datadog.nix
     ./dovecot.nix
     ./elasticsearch.nix
     ./external_net
     ./generic.nix
     ./haproxy.nix
     ./java.nix
     ./graylog/loghost.nix
     ./mailserver.nix
     ./mongodb
     ./mysql.nix
     ./nfs.nix
     ./nginx.nix
     ./postgresql.nix
     ./powerdns.nix
     ./redis.nix
     ./sensuserver.nix
     ./servicecheck.nix
     ./statshost.nix
     ./webdata_blackbee.nix
     ./webgateway.nix
     ./webproxy.nix
    ];

  options = {

    flyingcircus.active-roles = lib.mkOption {
      default = enc_roles;
      type = lib.types.listOf lib.types.str;

      description = ''
        Which roles to activate. E.g:

          flyingcircus.active-roles = [ "generic" "webgateway" "webproxy" ];

        Defaults to the roles provided by the ENC.

      '';
    };

  };

  config =
    # Map list of roles to a list of attribute sets enabling each role.
    let
      # Turn the list of role names (["a", "b"]) into an attribute set
      # ala { <role> = { enable = true;}; }
      role_set = lib.listToAttrs (
        map (role: { name = role; value = { enable = true; }; })
          cfg.active-roles);
    in
      {
        flyingcircus.roles = role_set;
      };

}
