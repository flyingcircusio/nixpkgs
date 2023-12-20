{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.haproxy;

  haproxyCfg = pkgs.writeText "haproxy.conf" ''
    global
      # needed for hot-reload to work without dropping packets in multi-worker mode
      stats socket /run/haproxy/haproxy.sock mode 600 expose-fd listeners level user

    ${cfg.config}
  '';

  globalOptions = {
    daemon = mkOption {
      default = true;
      type = bool;
      description = ''
        # `daemon`
        Makes the process fork into background. This is the recommended mode of
        operation. It is equivalent to the command line "-D" argument. It can be
        disabled by the command line "-db" argument. This option is ignored in
        systemd mode.

        From HAProxy Documentation
      '';
      example = false;
    };
    chroot = mkOption {
      default = "/var/empty";
      type = str;
      description = ''
        # `chroot <jail dir>`
        Changes current directory to <jail dir> and performs a chroot() there before
        dropping privileges. This increases the security level in case an unknown
        vulnerability would be exploited, since it would make it very hard for the
        attacker to exploit the system. This only works when the process is started
        with superuser privileges. It is important to ensure that <jail_dir> is both
        empty and non-writable to anyone.

        From HAProxy Documentation
      '';
      example = "/var/lib/haproxy";
    };
    user = mkOption {
      default = "haproxy";
      type = str;
      description = ''
        # `user <user name>`
        Changes the process's user ID to UID of user name <user name> from /etc/passwd.
        It is recommended that the user ID is dedicated to HAProxy or to a small set
        of similar daemons. HAProxy must be started with superuser privileges in order
        to be able to switch to another one.

        From HAProxy Documentation
      '';
      example = "hapuser";
    };
    group = mkOption {
      default = "haproxy";
      type = str;
      description = ''
        # `group <group name>`
        Changes the process's group ID to the GID of group name <group name> from
        /etc/group. It is recommended that the group ID is dedicated to HAProxy
        or to a small set of similar daemons. HAProxy must be started with a user
        belonging to this group, or with superuser privileges. Note that if haproxy
        is started from a user having supplementary groups, it will only be able to
        drop these groups if started with superuser privileges.

        From HAProxy Documentation
      '';
    };
    maxconn = mkOption {
      default = 4096;
      type = int;
      description = ''
        # `maxconn <number>`
        Sets the maximum per-process number of concurrent connections to <number>. It
        is equivalent to the command-line argument "-n". Proxies will stop accepting
        connections when this limit is reached. The "ulimit-n" parameter is
        automatically adjusted according to this value. See also "ulimit-n". Note:
        the "select" poller cannot reliably use more than 1024 file descriptors on
        some platforms. If your platform only supports select and reports "select
        FAILED" on startup, you need to reduce maxconn until it works (slightly
        below 500 in general). If this value is not set, it will automatically be
        calculated based on the current file descriptors limit reported by the
        "ulimit -n" command, possibly reduced to a lower value if a memory limit
        is enforced, based on the buffer size, memory allocated to compression, SSL
        cache size, and use or not of SSL and the associated maxsslconn (which can
        also be automatic).

        From HAProxy Documentation
      '';
    };
    extraConfig = mkOption {
      default = ''
        log localhost local2
        # Increase buffers for large URLs
        tune.bufsize 131072
        tune.maxrewrite 65536
      '';
      type = lines;
      description = ''
        Additional text appended to global section of haproxy config.
      '';
    };
  };

  defaultsOptions = {
    mode = modeOption // {
      default = "http";
    };
    options = optionsOption // {
      default = [
        "httplog"
        "dontlognull"
        "http-server-close"
      ];
    };
    timeout = timeoutOption // {
      default = {
        connect = "5s";
        client = "30s";
        server = "30s";
        queue = "25s";
      };
    };
    balance = balanceOption;
    extraConfig = mkOption {
      default = ''
        log global
      '';
      type = lines;
      description = ''
        Additional text appended to defaults section of haproxy config.
      '';
    };
  };

  listenOptions = builtins.foldl' attrsets.recursiveUpdate {} [
    frontendOptions
    backendOptions
    ({
      extraConfig = {
        description = ''
          Additional text appended to a listen section of haproxy config.
        '';
      };
    })
  ];

  frontendOptions = {
    mode = modeOption;
    timeout = timeoutOption;
    options = optionsOption;
    binds = mkOption {
      default = [];
      type = listOf str;
      description = ''
        # `bind [<address>]:<port_range> [, ...] [param*]`
        Defines the binding parameters of the local peer of this "peers" section.
        Such lines are not supported with "peer" line in the same "peers" section.

        From HAProxy Documentation
      '';
    };
    default_backend = mkOption {
      default = null;
      type = nullOr str;
      description = ''
        # `default_backend <backend>`
        Specify the backend to use when no "use_backend" rule has been matched.

        From HAProxy Documentation
      '';
    };
    extraConfig = mkOption {
      default = "";
      type = lines;
      description = ''
        Additional text appended to a frontend section of haproxy config.
      '';
    };
  };

  backendOptions = {
    mode = modeOption;
    timeout = timeoutOption;
    options = optionsOption;
    balance = balanceOption;
    servers = mkOption {
      default = [];
      type = listOf str;
      description = ''
        # `server <name> <address>[:[port]] [param*]`
        Declare a server in a backend

        From HAProxy Documentation
      '';
    };
    extraConfig = mkOption {
      default = "";
      type = lines;
      description = ''
        Additional text appended to a backend section of haproxy config.
      '';
    };
  };

  modeOption = mkOption {
    default = null;
    type = nullOr (enum [ "tcp" "http" "health" ]);
    description = ''
      # `mode <mode>`
      Sets the octal mode used to define access permissions on the UNIX socket. It
      can also be set by default in the global section's "unix-bind" statement.
      Note that some platforms simply ignore this. This setting is ignored by non
      UNIX sockets.

      From HAProxy Documentation
    '';
  };

  timeoutOption = mkOption {
    default = {};
    type = submodule {
      options = let
        timeoutOption = mkOption {
          default = null;
          type = nullOr str;
          description = ''
            Timeout for this event.
          '';
        };
      in {
        check = timeoutOption;
        client = timeoutOption;
        client-fin = timeoutOption;
        connect = timeoutOption;
        http-keep-alive = timeoutOption;
        http-request = timeoutOption;
        queue = timeoutOption;
        server = timeoutOption;
        server-fin = timeoutOption;
        tarpit = timeoutOption;
        tunnel = timeoutOption;
      };
    };
    description = ''
      # `timeout <event> <time>`
      Defines timeouts related to name resolution
        <event> : the event on which the <time> timeout period applies to.
                  events available are:
                  - resolve : default time to trigger name resolutions when no
                              other time applied.
                              Default value: 1s
                  - retry   : time between two DNS queries, when no valid response
                              have been received.
                              Default value: 1s
        <time>  : time related to the event. It follows the HAProxy time format.
                  <time> is expressed in milliseconds.

      From HAProxy Documentation
    '';
  };

  optionsOption = mkOption {
    default = [];
    type = listOf str;
    description = ''
      Options in this list are enabled.
    '';
  };

  balanceOption = mkOption {
    default = null;
    type = nullOr str;
    description = ''
      # `balance <algorithm> [ <arguments> ]`
      Define the load balancing algorithm to be used in a backend.
    '';
  };

  generateSection = sectionName: data: let
    sectionContent = optional (data.mode != null) "mode ${mode}"
      ++ optional (data ? balance && data.balance != null) "balance ${balance}"
      ++ optional (data ? options) concatStringsSep "\n" (map (option: "option ${option}") data.options)
      ++ optional (data ? timeout) concatStringsSep "\n" (map (key: value: "timeout ${key} ${value}") data.timeout)
      ++ optional (data ? binds) map (bind: "bind ${bind}") data.binds
      ++ optional (data ? default_backend && data.default_backend != null) "default_backend ${data.default_backend}"
      ++ optional (data ? servers) map (server: "server ${server}" data.servers)
      ++ splitString "\n" data.extraConfig;
   in ''
    ${sectionName}
    ${concatStringSep "\n" (map (line: "   " + line) sectionContent)}
  '';

  generatedConfig = with lib; with fclib; with cfg; (x: trivial.pipe x [ join unlines ]) [
    (with global; lib.flatten [
      ["global"]
      (indentWith "  " (lib.flatten [
        (if cfg.global.daemon then ["daemon"] else []) # daemon is already set and won't be shadowed
        ["chroot ${cfg.global.chroot}"]
        ["user ${cfg.global.user}"]
        ["group ${cfg.global.group}"]
        ["maxconn ${toString cfg.global.maxconn}"]
        (lines cfg.global.extraConfig)
      ]))
    ])
    ["\n"]
    (lib.flatten [
      ["defaults"]
      (generateSection cfg.defaults)
    ])
    ["\n"]
    (lib.flatten (lib.mapAttrsToList (name: data: ((lib.flatten [
      ["listen ${name}"]
      (generateSection data)
      ["\n"]
    ]))) cfg.listen))
    (lib.flatten (lib.mapAttrsToList (name: data: ((lib.flatten [
      ["frontend ${name}"]
      (generateSection data)
      ["\n"]
    ]))) cfg.frontend))
    (lib.flatten (lib.mapAttrsToList (name: data: ((lib.flatten [
      ["backend ${name}"]
      (generateSection data)
      ["\n"]
    ]))) cfg.backend))
    (lines cfg.extraConfig)
  ];

  haproxyCfg = pkgs.writeText "haproxy.conf" config.services.haproxy.config;

  configFiles = filter (lib.hasSuffix ".cfg") (fclib.files /etc/local/haproxy);
in {
  options = {
    services.haproxy = {

      enable = mkEnableOption (lib.mdDoc "HAProxy, the reliable, high performance TCP/HTTP load balancer.");

      package = mkPackageOptionMD pkgs "haproxy" { };

      user = mkOption {
        type = types.str;
        default = "haproxy";
        description = lib.mdDoc "User account under which haproxy runs.";
      };

      group = mkOption {
        type = types.str;
        default = "haproxy";
        description = lib.mdDoc "Group account under which haproxy runs.";
      };

      listenConfig = mkOption {
        default = {};
        example = literalExample ''{
          http-in = {
            binds = [
              "127.0.0.1:8002"
              "::1:8002"
            ];
            default_backend = "be";
          };
        }'';
        type = attrsOf (submodule {
          options = listenOptions;
        });
        description = ''
          Listen sections with statements.
        '';
      };

      defaultsConfig = mkOption {
        default = {};
        type = submodule {
          options = defaultsOptions;
        };
        description = ''
          Configuration statements for the defaults section.
        '';
      };

      frontendConfig = mkOption {
        default = {};
        type = attrsOf (submodule {
          options = frontendOptions;
        });
        description = ''
          Frontend sections with statements.
        '';
      };

      backendConfig = mkOption {
        default = {};
        example = literalExample ''{
          be = {
            servers = [
              "localhost localhost:8080"
            ];
          };
        }'';
        type = attrsOf (submodule {
          options = backendOptions;
        });
        description = ''
          Backend sections with statements.
        '';
      };

      config = mkOption {
        type = types.nullOr types.lines;
        default = null;
        description = lib.mdDoc ''
          Contents of the HAProxy configuration file,
          {file}`haproxy.conf`.
        '';
      };
      settings = mkOption {

      }
    };
  };

  config = mkIf cfg.enable {

    assertions = [{
      assertion = cfg.config != null;
      message = "You must provide services.haproxy.config.";
    }];

    # configuration file indirection is needed to support reloading
    environment.etc."haproxy.cfg".source = haproxyCfgContent;

    systemd.services.haproxy = {
      description = "HAProxy";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        User = cfg.user;
        Group = cfg.group;
        Type = "notify";
        ExecStartPre = [
          # when the master process receives USR2, it reloads itself using exec(argv[0]),
          # so we create a symlink there and update it before reloading
          "${pkgs.coreutils}/bin/ln -sf ${lib.getExe cfg.package} /run/haproxy/haproxy"
          # when running the config test, don't be quiet so we can see what goes wrong
          "/run/haproxy/haproxy -c -f ${haproxyCfg}"
        ];
        ExecStart = "/run/haproxy/haproxy -Ws -f /etc/haproxy.cfg -p /run/haproxy/haproxy.pid";
        # support reloading
        ExecReload = [
          "${lib.getExe cfg.package} -c -f ${haproxyCfg}"
          "${pkgs.coreutils}/bin/ln -sf ${lib.getExe cfg.package} /run/haproxy/haproxy"
          "${pkgs.coreutils}/bin/kill -USR2 $MAINPID"
        ];
        KillMode = "mixed";
        SuccessExitStatus = "143";
        Restart = "always";
        RuntimeDirectory = "haproxy";
        # upstream hardening options
        NoNewPrivileges = true;
        ProtectHome = true;
        ProtectSystem = "strict";
        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        ProtectControlGroups = true;
        SystemCallFilter= "~@cpu-emulation @keyring @module @obsolete @raw-io @reboot @swap @sync";
        # needed in case we bind to port < 1024
        AmbientCapabilities = "CAP_NET_BIND_SERVICE";
      };
    };

    users.users = optionalAttrs (cfg.user == "haproxy") {
      haproxy = {
        group = cfg.group;
        isSystemUser = true;
      };
    };

    users.groups = optionalAttrs (cfg.group == "haproxy") {
      haproxy = {};
    };
  };
}
