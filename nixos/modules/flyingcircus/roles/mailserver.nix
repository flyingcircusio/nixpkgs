{ config, lib, pkgs, ... }:

let

  cfg = config.flyingcircus;
  fclib = import ../lib;

  mailoutService = lib.findFirst
    (s: s.service == "mailserver-mailout")
    null
    config.flyingcircus.enc_services;

  myHostname = (fclib.configFromFile /etc/local/postfix/myhostname "");

  quoteIp6Address = address:
    if fclib.isIp6 address then
      "[${fclib.stripNetmask address}]/${toString (fclib.prefixLength address)}"
    else address;

  mainCf = [
    (if lib.pathExists "/etc/local/postfix/main.cf" then
      lib.readFile /etc/local/postfix/main.cf
     else "")

    (if lib.pathExists "/etc/local/postfix/canonical.pcre" then
      "canonical_maps = pcre:${/etc/local/postfix/canonical.pcre}\n"
     else "")
  ];

in
{
  options = {

    flyingcircus.roles.mailserver = {

      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Enable the Flying Circus mailserver out role and configure
          mailout on all nodes in this RG/location.

          Note: you still need to manually set "myhostname" and make proper
          DNS settings.
        '';
      };

    };
  };

  config = lib.mkMerge [

   (lib.mkIf cfg.roles.mailserver.enable {
      services.postfix.enable = true;

      # Allow all networks on the SRV interface. We expect only trusted machines
      # can reach us there (firewall).
      services.postfix.networks =
        if cfg.enc.parameters.interfaces ? srv then
          map
            quoteIp6Address
            (builtins.attrNames cfg.enc.parameters.interfaces.srv.networks)
        else [];

      # XXX change to fcio.net once #14970 is solved
      services.postfix.domain = "gocept.net";

      services.postfix.hostname = myHostname;

      services.postfix.extraConfig = lib.concatStringsSep "\n" mainCf;

      system.activationScripts.fcio-postfix = ''
          install -d -o root -g service  -m 02775 /etc/local/postfix/
        '';

      environment.etc."local/postfix/README.txt".text = ''
        Put your local postfix configuration here.

        Use `main.cf` for pure configuration settings like
        setting message_size_limit. Please do use normal main.cf syntax,
        as this will extend the basic configuration file.

        Make usage of `myhostname` to provide a hostname Postfix shall
        use to configure its own myhostname variable. If not set, the
        default hostname will be used instead.

        If you need to reference to some map, these are currently available:
        * canonical_maps - /etc/local/postfix/canonical.pcre

        In case you need to extend this list, get in contact with our
        support.
      '';

      environment.systemPackages = [ pkgs.mailutils ];

      security.sudo.extraConfig = ''
        %sensuclient    ALL=(postfix) ${pkgs.nagiosPluginsOfficial}/bin/check_mailq

      '';

      flyingcircus.services.sensu-client.checks = {

        postfix_mailq = {
          # The interpreter is not correctly set in file. Thus execute directly
          # via perl:
          command = ''
            /var/setuid-wrappers/sudo -u postfix \
            ${pkgs.nagiosPluginsOfficial}/bin/check_mailq \
              -M postfix -w 200 -c 400
            '';
          notification = "Postfix mailq too full.";
        };

        postfix_smtp_port = {
          command = ''
            ${pkgs.nagiosPluginsOfficial}/bin/check_smtp \
              -H localhost -p 25 -e Postfix -w 5 -c 10 -t 60
          '';
          notification = "Postfix smtp port (25) not reachable at localhost.";
        };

      };

    })

    (lib.mkIf (!cfg.roles.mailserver.enable &&
           mailoutService != null) {

      networking.defaultMailServer.directDelivery = true;
      networking.defaultMailServer.hostName = mailoutService.address;

      networking.defaultMailServer.root = "admin@flyingcircus.io";
      # XXX change to fcio.net once #14970 is solved
      networking.defaultMailServer.domain = "gocept.net";

      # Other parts of nixos (cron, mail) expect a suidwrapper for sendmail.
      services.mail.sendmailSetuidWrapper = {
        group = "root";
        owner = "root";
        permissions = "u+rx,g+x,o+x";
        program = "sendmail";
        setgid = false;
        setuid = false; };

    })
  ];
}
