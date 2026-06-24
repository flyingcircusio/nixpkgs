{
  config,
  lib,
  pkgs,
  ...
}:


let

  cfg = config.networking;

in

{

  meta.maintainers = with lib.maintainers; [ theuni ];

  config = lib.mkIf (cfg.backend == "ifstate") {

    networking.ifstate.enable = true;

    systemd.services.resolvconf-setup = {
      after = [
        "network-pre.target"
        "systemd-sysusers.service"
        "systemd-sysctl.service"
      ];
      before = [
        "network.target"
        "multi-user.target"
        "shutdown.target"
        "initrd-switch-root.target"
      ];
      wantedBy = [
        "multi-user.target"
      ];
      conflicts = [
        "shutdown.target"
        "initrd-switch-root.target"
      ];
      wants = [
        "network.target"
      ];

      unitConfig = {
        # Avoid default dependencies like "basic.target", which prevents ifstate from starting before luks is unlocked.
        DefaultDependencies = "no";
      };

      description = "resolv.conf";

      serviceConfig = {
        Type = "oneshot";
        TimeoutStartSec = "2min";
      };

      script =
        let
          cfg = config.networking;
        in
        ''
          ${lib.optionalString cfg.resolvconf.enable ''
            # Set the static DNS configuration, if given.
            ${pkgs.openresolv}/sbin/resolvconf -m 1 -a static <<EOF
            ${lib.optionalString (cfg.nameservers != [ ] && cfg.domain != null) ''
              domain ${cfg.domain}
            ''}
            ${lib.optionalString (cfg.search != [ ]) ("search " + lib.concatStringsSep " " cfg.search)}
            ${lib.flip lib.concatMapStrings cfg.nameservers (ns: ''
              nameserver ${ns}
            '')}
            EOF
          ''}
        '';
    };

  };

}
