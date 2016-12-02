{ lib, config, ... }:
{
  options = with lib.types; {
    flyingcircus.syslog.separateFacilities = lib.mkOption {
      default = {};
      example = {
        local2 = "/var/log/haproxy.log";
      };
      description = "";
      type = attrs;
    };
    flyingcircus.syslog.extraRules = lib.mkOption {
      default = "";
      example = ''
        *.* @graylog.example.org:514
      '';
      description = "custom extra rules for syslog";
      type = string;
    };
  };

  config =
  let
    exclude = lib.concatMapStrings
      (facility: ";${facility}.none")
      (builtins.attrNames config.flyingcircus.syslog.separateFacilities);
    separateFacilities = lib.concatStrings (lib.mapAttrsToList
      (facility: file: "${facility}.info -${file}\n")
      config.flyingcircus.syslog.separateFacilities);
    extraLogFiles = lib.concatStringsSep " "
      (builtins.attrValues config.flyingcircus.syslog.separateFacilities);
    extraRules = config.flyingcircus.syslog.extraRules;
  in
  {
    services.rsyslogd.enable = true;

    services.rsyslogd.defaultConfig = ''
      $AbortOnUncleanConfig on

      # Reduce repeating messages (default off)
      $RepeatedMsgReduction on

      # Carry complete tracebacks etc.: large messages and don't escape newlines
      $DropTrailingLFOnReception off
      $EscapeControlCharactersOnReceive off
      $MaxMessageSize 64k
      $SpaceLFOnReceive on

      # Inject "--MARK--" messages every $Interval (seconds)
      module(load="immark" Interval="600")

      # Read syslog messages from UDP
      module(load="imudp")
      input(type="imudp" address="127.0.0.1" port="514")
      input(type="imudp" address="::1" port="514")
    '';

    services.rsyslogd.extraConfig = ''
      *.info${exclude} -/var/log/messages
      ${extraRules}
      ${separateFacilities}
    '';

    services.logrotate.config = ''
      /var/log/messages /var/log/lastlog /var/log/wtmp ${extraLogFiles} {
        postrotate
          if [[ -f /run/rsyslogd.pid ]]; then
            kill -HUP $(< /run/rsyslogd.pid )
          fi
        endscript
      }
    '';

    # fall-back clean rule for "forgotten" logs
    systemd.tmpfiles.rules = [
      "d /var/log 0755 root root 180d"
    ];
  };
}
