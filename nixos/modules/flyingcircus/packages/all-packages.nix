{ pkgs }:

rec {

  boost159 = pkgs.callPackage ./boost/1.59.nix { };
  boost160 = pkgs.callPackage ./boost/1.60.nix { };

  cron = pkgs.callPackage ./cron.nix { };
  collectd = pkgs.callPackage ./collectd { 
    libsigrok = null;
    libvirt = null;
    lm_sensors = null;  # probably not seen on VMs
    lvm2 = null;        # dito
  };
  dnsmasq = pkgs.callPackage ./dnsmasq.nix { };

  easyrsa3 = pkgs.callPackage ./easyrsa { openssl = pkgs.openssl_1_0_2; };
  elasticsearch = pkgs.callPackage ./elasticsearch { };

  fcmaintenance = pkgs.callPackage ./fcmaintenance { };
  fcmanage = pkgs.callPackage ./fcmanage { };
  fcsensuplugins = pkgs.callPackage ./fcsensuplugins { };

  innotop = pkgs.callPackage ./percona/innotop.nix { };

  linux = linux_4_4;
  linux_4_4 = pkgs.callPackage ./kernel/linux-4.4.nix {
    kernelPatches = [ pkgs.kernelPatches.bridge_stp_helper ];
  };
  linuxPackages = linuxPackages_4_4;
  linuxPackages_4_4 = pkgs.recurseIntoAttrs
    (pkgs.linuxPackagesFor linux_4_4 linuxPackages_4_4);

  mc = pkgs.callPackage ./mc.nix { };
  mailx = pkgs.callPackage ./mailx.nix { };
  mongodb = pkgs.callPackage ./mongodb { sasl = pkgs.cyrus_sasl; };

  nagiosPluginsOfficial = pkgs.callPackage ./nagios-plugins-official-2.x.nix {};
  nodejs6 = pkgs.callPackage ./nodejs6/default.nix {
    libuv = pkgs.libuvVersions.v1_9_1;
    openssl = pkgs.openssl_1_0_2;
  };

  openssl = openssl_1_0_1;

  inherit (pkgs.callPackages ./openssl {
      fetchurl = pkgs.fetchurlBoot;
      cryptodevHeaders = pkgs.linuxPackages.cryptodev.override {
        fetchurl = pkgs.fetchurlBoot;
        onlyHeaders = true;
      };
    })
    openssl_1_0_1
    openssl_1_0_2
    openssl_1_1_0;

  osm2pgsql = pkgs.callPackage ./osm2pgsql.nix { };

  percona = percona57;
  percona57 = pkgs.callPackage ./percona/5.7.nix { boost = boost159; };
  percona56 = pkgs.callPackage ./percona/5.6.nix { boost = boost159; };
  postfix = pkgs.callPackage ./postfix/3.0.nix { };
  powerdns = pkgs.callPackage ./powerdns.nix { };

  qemu = pkgs.callPackage ./qemu-2.5.nix {
    inherit (pkgs.darwin.apple_sdk.frameworks) CoreServices Cocoa;
    x86Only = true;
  };
  qpress = pkgs.callPackage ./percona/qpress.nix { };

  rabbitmq_delayed_message_exchange =
    pkgs.callPackage ./rabbitmq_delayed_message_exchange.nix { };

  sensu = pkgs.callPackage ./sensu { };

  uchiwa = pkgs.callPackage ./uchiwa { };

  varnish =
    (pkgs.callPackage ../../../../pkgs/servers/varnish { }).overrideDerivation
    (old: {
      buildFlags = "localstatedir=/var/spool";
    });
  vulnix = pkgs.callPackage ./vulnix { };

  xtrabackup = pkgs.callPackage ./percona/xtrabackup.nix { };

}
