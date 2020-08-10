# NOTES:
# * Mongo cluster setup requires manual intervention.

{ config, lib, pkgs, ... }:

with lib;
let
  cfg = config.flyingcircus.roles.graylog;
  fclib = import ../lib;

  listenOn = "${config.networking.hostName}.${config.networking.domain}";
  serviceUser = "graylog";

  # -- files --
  # XXX it helps a lot if the admin password is the same on all nodes. Hence
  # we should generate it somehow. But how?!
  rootPasswordFile = "/etc/local/graylog/password";
  passwordSecretFile = "/etc/local/graylog/password_secret";

  rootPassword = fclib.servicePassword {
    inherit pkgs;
    file = rootPasswordFile;
    token = config.networking.hostName;
  };
  rootPasswordSha2 = mkSha2 rootPassword.value;

  passwordSecret = fclib.servicePassword {
    inherit pkgs;
    file = passwordSecretFile;
    token = config.networking.hostName;
  };

  glAPIPort = 9001;
  glAPIHAPort = 8002;
  gelfTCPHAPort = 12201;
  gelfTCPGraylogPort = 12202;

  webListenPath = "/";
  webListenUri = "http://${listenOn}:${toString glAPIPort}${webListenPath}";
  restListenUri = "http://${listenOn}:${toString glAPIPort}/api";

  # -- helper functions --
  mkSha2 = text:
    removeSuffix "\n" (readFile
    (pkgs.runCommand "mkSha2" {
      inherit text;
      preferLocalBuild = true;
      passAsFile = [ "text" ];
    } "sha256sum < $textPath | cut -f1 -d \" \" > $out"));

  logstashSSLHelper = with pkgs; writeScriptBin "logstash_ssl_import" ''
    #!${stdenv.shell}
    set -eu

    puppet="puppet.$FCIO_LOCATION.gocept.net"
    pw=$(${pwgen}/bin/pwgen -1 18)

    scp $puppet:/var/lib/puppet/lumberjack/keys/$FCIO_HOSTNAME.{crt,key} /var/lib/graylog/
    (cd /var/lib/graylog
     ${openssl}/bin/openssl pkcs12 -export -in $FCIO_HOSTNAME.crt \
                 -inkey $FCIO_HOSTNAME.key \
                 -out $FCIO_HOSTNAME.p12 \
                 -name $FCIO_HOSTNAME \
                 -passin pass:$pw \
                 -passout pass:$pw
     rm -f $FCIO_HOSTNAME.jks
     ${openjdk}/bin/keytool -importkeystore \
                 -srckeystore $FCIO_HOSTNAME.p12 \
                 -srcstoretype PKCS12\
                 -srcstorepass $pw \
                 -alias $FCIO_HOSTNAME \
                 -deststorepass $pw \
                 -destkeypass $pw \
                 -destkeystore $FCIO_HOSTNAME.jks
                 )
    echo "keystore: /var/lib/graylog/$FCIO_HOSTNAME.jks"
    echo "password: $pw"
  '';

  glNodes =
    fclib.listServiceAddresses config "loghost-server" ++
    fclib.listServiceAddresses config "graylog-server";

  logTargets = lib.unique (
    # Pick one of the regular graylog servers ...
    (if (length glNodes > 0) then
      [(head glNodes)] else []) ++

    # ... and add the central one (if it exists).
    (fclib.listServiceAddresses config "loghost-location-server"));

  replSetName = if cfg.cluster then "graylog" else "";

  isMaster =
    (head glNodes)
    == "${config.networking.hostName}.${config.networking.domain}";

in
{

  options = {

    flyingcircus.roles.graylog = {

      enable = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Enable the Graylog role.

          Note: there can be multiple graylogs per RG, unlike loghost.
        '';
      };

      cluster = mkOption {
        type = types.bool;
        default = true;
        description = "Build a GL cluster. Ususally disabled by loghost role.";
      };

      rootPassword = mkOption {
        type = types.nullOr types.string;
        default = null;
        description = ''
          The password for of your graylogs's webui root user. If null, a random password will be generated.
        '';
      };

      passwordSecret = mkOption {
        type = types.nullOr types.string;
        default = null;
        description = ''
          A password secret for graylog. Use the same password secret fo the whole graylog
          cluster. If null, a random password will be generated.
        '';
      };

      heapPercentage = mkOption {
        type = types.int;
        default = 70;
        description = "How much RAM should go to graylog heap.";
      };

      esNodes = mkOption {
        type = types.listOf types.string;
        description = "List of elasticsearch nodes";
      };

      syslogInputPort = mkOption {
        type = types.int;
        default = 5140;
        description = "UDP Port for the Graylog syslog input.";
      };

      publicFrontend = {

        enable = mkOption {
          type = types.bool;
          default = false;
          description = "Configure Nginx for GL UI on FE at 80/443?";
        };

        ssl = mkOption {
          type = types.bool;
          default = false;
          description = ''
            Enable SSL. This is disabled initially to be able to provide a cert
            via Let's Encrypt.

            It epects

            * /etc/local/nginx/graylog.crt, and
            * /etc/local/nginx/graylog.key

            to be present.

          '';
        };

        hostName = mkOption {
          type = types.nullOr types.str;
          default = "graylog.${config.flyingcircus.enc.parameters.resource_group}.fcio.net";
          description = "HTTP host name for the GL frontend.";
          example = "graylog.example.com";
        };
      };

    };
  };

  config = mkMerge [

    (mkIf cfg.enable {
      environment.systemPackages = [ logstashSSLHelper ];

      networking.firewall.allowedTCPPorts = [ 9000 9002 ];

      flyingcircus.roles.nginx.enable = true;
      flyingcircus.roles.nginx.httpConfig =
      let
        listenOnPort = fclib.nginxListenOn config;
        allow = ips: lib.concatMapStringsSep "\n    "
            (addr: "allow ${addr};")
            (ips);
      in ''
        # Direct access w/o prior authentication. This is useful for API access.
        # Strip Remote-User as there is nothing in between the user and us.
        server {
            ${listenOnPort "ethsrv" 9002}

            location / {
                proxy_set_header Remote-User "";
                proxy_set_header X-Graylog-Server-URL http://${config.networking.hostName}.${config.networking.domain}:9002/api;
                proxy_pass http://${listenOn}:${toString glAPIHAPort};
            }

          }

      '' + optionalString (cfg.publicFrontend.enable && !cfg.publicFrontend.ssl) ''
        # Frontend FE interface at 80/443
        server {
          ${listenOnPort "ethfe" 80}
          server_name ${cfg.publicFrontend.hostName};

          location /.well-known {
              root /tmp/letsencrypt;
          }

          location / {
              proxy_set_header Remote-User "";
              proxy_set_header X-Graylog-Server-URL http://${cfg.publicFrontend.hostName}:80/api;
              proxy_pass http://${listenOn}:${toString glAPIHAPort};
          }

          location /admin {
              auth_basic "FCIO user";
              auth_basic_user_file "/etc/local/nginx/htpasswd_fcio_users";
              proxy_pass http://${listenOn}:${toString glAPIHAPort};
          }

        }
      '' + optionalString (cfg.publicFrontend.enable && cfg.publicFrontend.ssl) ''
        server {
          ${listenOnPort "ethfe" 80}
          server_name ${cfg.publicFrontend.hostName};

          location /.well-known {
              root /tmp/letsencrypt;
          }

          location = / {
              rewrite ^ https://$server_name$request_uri redirect;
          }
        }

        server {
          ${listenOnPort "ethfe" "443 ssl http2"}
          server_name ${cfg.publicFrontend.hostName};

          ssl_certificate ${/etc/local/nginx/graylog.crt};
          ssl_certificate_key ${/etc/local/nginx/graylog.key};

          location / {
              proxy_set_header Remote-User "";
              proxy_set_header X-Graylog-Server-URL https://${cfg.publicFrontend.hostName}:443/api;
              proxy_pass http://${listenOn}:${toString glAPIHAPort};
          }

          location /admin {
              auth_basic "FCIO user";
              auth_basic_user_file "/etc/local/nginx/htpasswd_fcio_users";
              proxy_pass http://${listenOn}:${toString glAPIHAPort};
          }
        }

      '';

      system.activationScripts.fcio-loghost =
        stringAfter [ "users" "groups" ] ''
          ${rootPassword.activation}
          ${passwordSecret.activation}
        '';

      services.graylog = {
        enable = true;
        inherit rootPasswordSha2 webListenUri restListenUri;
        passwordSecret = passwordSecret.value;
        elasticsearchHosts = cfg.esNodes;
        javaHeap = ''${toString
          (fclib.max [
            ((fclib.current_memory config 1024) * cfg.heapPercentage / 100)
            768
            ])}m'';
        mongodbUri = let
          repl = if cfg.cluster then "?replicaSet=${replSetName}" else "";
          mongodbNodes = concatStringsSep ","
              (map (node: "${node}:27017") glNodes);
          in
            "mongodb://${mongodbNodes}/graylog${repl}";
        isMaster = isMaster;
        plugins = with pkgs.graylogPlugins;
          [ logstash
            slack
          ];
        extraConfig = let
            slash = addr: if fclib.isIp4 addr then "/32" else "/128";
            trustedProxies =
              concatStringsSep ", " (
                map
                  (a: (fclib.stripNetmask a.ip) + (slash a.ip))
                  (filter
                    (a: builtins.elem "${a.name}.${config.networking.domain}" glNodes)
                    config.flyingcircus.enc_addresses.srv));
          in ''
            trusted_proxies = ${trustedProxies}
            processbuffer_processors = ${toString
              (fclib.max [
                ((fclib.current_cores config 1) - 2)
                5])}
            outputbuffer_processors = ${toString
              (fclib.max [
                ((fclib.current_cores config 1) / 2)
                3])}
          '';
      };

      flyingcircus.roles.mongodb32.enable = true;
      services.mongodb.replSetName = replSetName;
      services.mongodb.extraConfig = ''
        storage.wiredTiger.engineConfig.cacheSizeGB: 1
      '';

      systemd.services.graylog-config = {
        description = "Configure Graylog FCIO settings";
        requires = [ "graylog.service" ];
        after = [ "graylog.service" "mongodb.service" "elasticsearch.service" ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          Type = "oneshot";
          User = config.services.graylog.user;
          RemainAfterExit = true;
        };
        script = let
          api = restListenUri;
          user = "admin";
          pw = rootPassword.value;

          syslog_udp_configuration = {
            configuration = {
              bind_address = "0.0.0.0";
              port = cfg.syslogInputPort;
            };
            title = "Syslog UDP"; # be careful changing it, it's used as
                                  # a primary key for identifying the config
                                  # object
            type = "org.graylog2.inputs.syslog.udp.SyslogUDPInput";
            global = true;
          };

          gelf_tcp_configuration = {
            configuration = {
              bind_address = "0.0.0.0";
              port = gelfTCPGraylogPort;
            };
            title = "GELF TCP";
            type = "org.graylog2.inputs.gelf.tcp.GELFTCPInput";
            global = true;
          };

          geodb_configuration = {
            enabled = true;
            db_type = "MAXMIND_CITY";
            db_path = "/var/lib/graylog/GeoLite2-City.mmdb";
          };

          ldap_configuration = {
              enabled = true;
              system_username = fclib.getLdapNodeDN config;
              system_password = fclib.getLdapNodePassword config;
              ldap_uri = "ldaps://ldap.rzob.gocept.net:636/";
              trust_all_certificates = true;
              use_start_tls = false;
              active_directory = false;
              search_base = "ou=People,dc=gocept,dc=com";
              search_pattern = "(&(&(objectClass=inetOrgPerson)(uid={0}))(memberOf=cn=${config.flyingcircus.enc.parameters.resource_group},ou=GroupOfNames,dc=gocept,dc=com))";
              display_name_attribute = "displayName";
              default_group = "Admin";
          };

          configure_graylog_raw = what: ''
            ${pkgs.fcmanage}/bin/fc-graylog \
              -u '${user}' \
              -p '${pw}' \
              ${api} \
              configure \
              ${what}
            '';
          configure_graylog_input = input:
            configure_graylog_raw "--input '${builtins.toJSON input}'";

          configure_graylog = path: configuration: configure_graylog_raw ''
              --raw-path ${path} \
              --raw-data '${builtins.toJSON configuration}' '';
        in ''
          ${configure_graylog_input syslog_udp_configuration}
          ${configure_graylog_input gelf_tcp_configuration}

          ${configure_graylog
            "/system/cluster_config/org.graylog.plugins.map.config.GeoIpResolverConfig"
            geodb_configuration}
          ${configure_graylog
            "/system/ldap/settings"
            ldap_configuration}
        '';
      };

      systemd.services.graylog-update-geolite = {
        description = "Update geolite db for graylog";
        restartIfChanged = false;
        after = [ "graylog.service" ];
        serviceConfig = {
          User = config.services.graylog.user;
          Type = "oneshot";
        };

        script = ''
          cd /var/lib/graylog
          ${pkgs.curl}/bin/curl -O http://geolite.maxmind.com/download/geoip/database/GeoLite2-City.mmdb.gz
          ${pkgs.gzip}/bin/gunzip -f GeoLite2-City.mmdb.gz
        '';
      };

      systemd.timers.graylog-update-geolite = {
        description = "Timer for updating the geolite db for graylog";
        wantedBy = [ "timers.target" ];
        timerConfig = {
          Unit = "graylog-update-geolite.service";
          OnStartupSec = "10m";
          OnUnitActiveSec = "30d";
          # Not yet supported by our systemd version.
          # RandomSec = "3m";
        };
      };

      systemd.services.graylog-collect-journal-age-metric = rec {
        description = "Collect journal age and report to Telegraf";
        wantedBy = [ "graylog.service" "telegraf.service"];
        after = wantedBy;
        serviceConfig = {
          User = "telegraf";
          Restart = "always";
          RestartSec = "10";
          ExecStart = ''
            ${pkgs.fcmanage}/bin/fc-graylog \
              -u admin \
              -p '${rootPassword.value}' \
              ${restListenUri} \
              collect_journal_age_metric --socket-path /run/telegraf/influx.sock

          '';
        };
      };

      services.collectd.extraConfig = ''
        LoadPlugin curl_json
        <Plugin curl_json>
          <URL "${restListenUri}/system/journal">
            User "admin"
            Password "${rootPassword.value}"
            Header "Accept: application/json"
            Instance "graylog"
            <Key "uncommitted_journal_entries">
              Type "gauge"
            </Key>
            <Key "append_events_per_second">
              Type "gauge"
            </Key>
            <Key "read_events_per_second">
              Type "gauge"
            </Key>
          </URL>
          <URL "${restListenUri}/system/throughput">
            User "admin"
            Password "${rootPassword.value}"
            Header "Accept: application/json"
            Instance "graylog"
            <Key "throughput">
              Type "gauge"
            </Key>
          </URL>
        </Plugin>
      '';

      services.telegraf.inputs.graylog = [{
        servers = [ "http://localhost:9003/api/system/metrics/multiple" ];
        metrics = [ "jvm.memory.total.committed"
                    "jvm.memory.total.used"
                    "jvm.threads.count"
                    "org.graylog2.buffers.input.size"
                    "org.graylog2.buffers.input.usage"
                    "org.graylog2.buffers.output.size"
                    "org.graylog2.buffers.output.usage"
                    "org.graylog2.buffers.process.size"
                    "org.graylog2.buffers.process.usage"
                    "org.graylog2.journal.oldest-segment"
                    "org.graylog2.journal.size"
                    "org.graylog2.journal.size-limit"
                    "org.graylog2.throughput.input"
                    "org.graylog2.throughput.output" ];
        username = "admin";
        password = rootPassword.value;
      }];

      flyingcircus.services.sensu-client.checks = {
        graylog_ui = {
          notification = "Graylog UI alive";
          command = ''
            check_http -H ${listenOn} -p ${toString glAPIPort} \
              -u ${webListenPath}/
          '';
        };
      };

      # HAProxy load balancer.
      # Since haproxy is rather lightweight we just fire up one on each graylog
      # node, talking to all known graylog nodes.
      flyingcircus.roles.haproxy.enable = true;
      services.haproxy.config = mkForce (let
        backendConfig = node_config: concatStringsSep "\n"
          (map
            (node: "    " + (node_config node))
            glNodes);
        listenConfig = port: concatStringsSep "\n"
          (map
            (addr: "    bind ${addr}:${toString port}")
            (fclib.listenAddresses config "ethsrv"));
      in ''
        global
            daemon
            chroot /var/empty
            user haproxy
            group haproxy
            maxconn 4096
            log localhost local2
            stats socket ${config.flyingcircus.roles.haproxy.statsSocket} mode 660 group nogroup level operator

        defaults
            mode http
            log global
            option httplog
            option dontlognull
            option http-keep-alive
            option redispatch

            timeout connect 5s
            timeout client 30s    # should be equal to server timeout
            timeout server 30s    # should be equal to client timeout
            timeout queue 30s

        listen gelf-tcp-in
        ${listenConfig gelfTCPHAPort}
            mode tcp
            default_backend gelf_tcp

        listen graylog_http
        ${listenConfig glAPIHAPort}
            use_backend stats if { path_beg /admin/stats }
            default_backend graylog

        listen graylog_metrics
            bind localhost:9003
            http-request add-header X-Requested-By Telegraf
            server local_graylog ${listenOn}:${toString glAPIPort}

        backend gelf_tcp
            mode tcp
            balance leastconn
            option tcplog
            option httpchk HEAD /api/system/lbstatus
            timeout server 10s
            timeout client 10s
            timeout tunnel 61s
        ${backendConfig (node:
            "server ${node}  ${node}:${toString gelfTCPGraylogPort} check port ${toString glAPIPort} inter 10s rise 2 fall 1")}

        backend graylog
            balance roundrobin
            option httpchk GET /api
            timeout client 121s    # should be equal to server timeout
            timeout server 121s    # should be equal to client timeout
        ${backendConfig (node:
            "server ${node}  ${node}:${toString glAPIPort} check fall 1 rise 2 inter 10s maxconn 20")}

        backend stats
            stats uri /
            stats refresh 5s
      '');

      })

    (mkIf (length logTargets > 0) {
      # Forward all syslog to graylog, if there is one.
      flyingcircus.syslog.extraRules = concatStringsSep "\n"
              (map (target: "*.* @${target}:${toString cfg.syslogInputPort};RSYSLOG_SyslogProtocol23Format") logTargets);
    })

    {
      flyingcircus.roles.statshost.prometheusMetricRelabel = [
        {
          source_labels = [ "__name__" ];
          regex = "(org_graylog2)_(.*)$";
          replacement = "graylog_\${2}";
          target_label = "__name__";
        }
      ];
      flyingcircus.roles.statshost.globalAllowedMetrics = [ "graylog" ];
    }

  ];
}
