{ pkgs, lib, system, hydraJob }:

{
  apache = hydraJob (import ./apache/apache.nix { inherit system; });
  apache_mod_php56 = hydraJob (import ./apache/apache_mod_php56.nix { inherit system; });

  clamav = hydraJob (import ./clamav.nix { inherit system; });

  docsplit = hydraJob (import ./docsplit { inherit system; });

  elasticsearch = hydraJob
    (import ./elasticsearch.nix { rolename = "elasticsearch"; });
  elasticsearch2 = hydraJob
    (import ./elasticsearch.nix { rolename = "elasticsearch2"; });
  elasticsearch5 = hydraJob
    (import ./elasticsearch.nix { rolename = "elasticsearch5"; });

  firewall = hydraJob (import ./firewall/atomic.nix { inherit system; });

  graylog = hydraJob (import ./graylog.nix { inherit system; });

  haproxy = hydraJob (import ./haproxy.nix { inherit system; });

  kibana = hydraJob (import ./kibana.nix { inherit system; });

  ldapserver =  hydraJob (import ./ldapserver.nix { inherit system; });
  login = hydraJob (import ./login.nix { inherit system; });

  mariadb = hydraJob (import ./mariadb.nix { inherit system; });

  memcached = hydraJob (import ./memcached.nix { inherit system; });

  mongodb = hydraJob (import ./mongodb { inherit system; });

  inherit (import ./nodejs.nix { inherit system hydraJob; })
    nodejs_4 nodejs_6 nodejs_7 nodejs_8 nodejs_9;

  inherit (import ./mysql.nix { inherit system hydraJob; })
    mysql_5_5 mysql_5_6 mysql_5_7;

  oraclejava = hydraJob (import ./oraclejava.nix { inherit system; });

  pdftk = hydraJob (import ./pdftk.nix { inherit system; });

  phpzts = hydraJob (import ./phpzts.nix { inherit system; });

  postgresql_9_3 = hydraJob
    (import ./postgresql.nix { rolename = "postgresql93"; });
  postgresql_9_4 = hydraJob
    (import ./postgresql.nix { rolename = "postgresql94"; });
  postgresql_9_5 = hydraJob
    (import ./postgresql.nix { rolename = "postgresql95"; });
  postgresql_9_6 = hydraJob
    (import ./postgresql.nix { rolename = "postgresql96"; });
  postgresql_10 = hydraJob
    (import ./postgresql.nix { rolename = "postgresql10"; });

  prometheus = hydraJob (import ./prometheus.nix { inherit system; });

  rabbitmq = hydraJob (import ./rabbitmq.nix { inherit system; });

  sensuserver = hydraJob (import ./sensu.nix { inherit system; });
  statshost-master = hydraJob (import ./statshost-master.nix { inherit system; });
  statshost-global = hydraJob (import ./statshost-global.nix { inherit system; });
  systemdCycles = hydraJob (import ./systemd_cycles.nix { inherit system; });

  users = hydraJob (import ./users { inherit system; });
}
