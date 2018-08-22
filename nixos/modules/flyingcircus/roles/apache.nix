{ config, lib, pkgs, ... }: with lib;

let
  cfg = config.flyingcircus;
  fclib = import ../lib;

  localConfigFiles = filter
    (filename: hasSuffix ".conf" filename)
    (fclib.files "/etc/local/apache");
  hasLocalConfig = localConfigFiles != [];
  localConfig =
    # Apache dies, if there is no *.conf file
    if hasLocalConfig
    then "Include ${/etc/local/apache}/*.conf"
    else "";

  serverStatusPort = 9128;

in
{

  options = {

    flyingcircus.roles.apache = {

      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable the Flying Circus apache server role.";
      };
    };

  };

  config = mkMerge [
    (mkIf cfg.roles.apache.enable {

    services.httpd.enable = true;
    services.httpd.group = "service";
    services.httpd.adminAddr = "nobody@example.com";
    services.httpd.multiProcessingModule = "worker";
    services.httpd.port = serverStatusPort;
    services.httpd.extraModules = [ "proxy_fcgi" ];

    services.httpd.extraConfig = ''
      ExtendedStatus on
      <Location "/server-status">
          SetHandler server-status
          Require ip 127.0.0.1
      </Location>

      ${localConfig}
    '';

    systemd.services.httpd.preStart = ''
      install -d -o ${config.services.httpd.user} -g service -m 02775 /etc/local/apache
      install -d -o root -g service -m 02755 ${config.services.httpd.logDir}
    '';

    services.logrotate.config = ''
        /var/log/httpd/*access*log
        /var/log/httpd/*error*log
        {
            rotate 92
            create 0644 root service
            postrotate
                systemctl kill httpd -s USR1 --kill-who=main
            endscript
        }
    '';

    services.telegraf.inputs = {
      apache = [{
        urls = ["http://127.0.0.1:${toString serverStatusPort}/server-status?auto"];
      }];
    };


    environment.etc = {

      "local/apache/README.txt".text = ''
        Apache httpd is enabled on this machine.

        Put your site configuration into this directory as `*.conf`. You may
        add other files, like SSL keys, as well.

        There is also an `example-configuration` here.

      '';

      "local/apache/example-configuration".text = ''
        Listen 8080
        <VirtualHost *:8000>
            ServerName www.example.com
            ServerAlias www2.example.com

            DocumentRoot "/srv/s-service/htdocs"

            <Directory "/srv/s-service/htdocs">
                AllowOverride all
                Require all granted
                Options FollowSymlinks
                DirectoryIndex index.php index.htm
            </Directory>

            <LocationMatch "^(.*\.php)$">
                ProxyPass fcgi://127.0.0.1:9003/srv/s-service/htdocs$1
            </LocationMatch>
        </VirtualHost>
      '';
    };
  })

  {
    flyingcircus.roles.statshost.globalAllowedMetrics = [ "apache" ];
  }
  ];
}
