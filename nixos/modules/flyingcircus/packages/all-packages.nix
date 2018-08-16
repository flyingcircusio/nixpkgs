{ pkgs ? (import <nixpkgs> {})
, lib ? pkgs.lib
, stdenv ? pkgs.stdenv
}:

with lib;

let
  # Fold multiple outputs (a.k.a. closure size reduction) into a single
  # "old-school" derivation.
  mergeOutputs = keep: original:
    pkgs.buildEnv {
      name = original.name;
      paths = [ original ] ++ original.propagatedBuildInputs;
      ignoreCollisions = true;
      outputsToLink = intersectLists keep original.outputs;
    };

  # Please leave the double import in place (the channel build will fail
  # otherwise).
  pkgs_18_03_src = (import <nixpkgs> {}).fetchFromGitHub {
    owner = "NixOS";
    repo = "nixpkgs";
    rev = "b6646cb";
    sha256 = "1wm3jdkx06i9yr2hgmxap8rxhp54q2f5ds83k6iig9xjmyf4pl0a";
  };
  pkgs_18_03 = import pkgs_18_03_src {};

  # Please leave the double import in place (the channel build will fail
  # otherwise).
  pkgs_17_09_src = (import <nixpkgs> {}).fetchFromGitHub {
    owner = "NixOS";
    repo = "nixpkgs";
    rev = "0d856d8";
    sha256 = "0pqsk61kkzqqb79jp5rhn7ay5ld7h02hd8nas23qn6ibp1mv7aa1";
  };
  pkgs_17_09 = import pkgs_17_09_src {};

in rec {

  # Important: register these sources in platform/garbagecollect/default.nix!
  inherit pkgs_17_09_src;
  inherit pkgs_18_03_src;

  # === Imports from newer upstream versions ===

  inherit (pkgs_18_03)
    bazaar
    nodejs-6_x
    nodejs-8_x
    nodejs-9_x
    pipenv
    shadow
    vim;

  inherit (pkgs_17_09)
    apacheHttpd
    audiofile
    buildBowerComponents
    bundlerApp
    elasticsearch2
    elasticsearch5
    fetchbower
    firefox
    ghostscript
    git
    graphicsmagick
    iptables
    jbig2dec
    kibana
    libreoffice-fresh
    mailutils
    nix
    nodejs-4_x
    php56
    php56Packages
    php70
    php70Packages
    php71
    php71Packages
    prometheus
    prometheus-haproxy-exporter
    python35
    python35Packages
    python36
    python36Packages
    remarshal
    ripgrep
    ronn
    samba
    strongswan
    subversion18
    virtualbox
    wkhtmltopdf
    xulrunner;

  libtiff = mergeOutputs [ "out" "bin" "dev" ] pkgs_17_09.libtiff;
  libsndfile = mergeOutputs [ "out" "bin" "dev" ] pkgs_17_09.libsndfile;
  libvorbis = mergeOutputs [ "out" "dev" ] pkgs_17_09.libvorbis;
  libjpeg-turbo = mergeOutputs [ "out" "bin" "dev" ] pkgs_17_09.libjpeg;
  libjpeg = libjpeg-turbo;

  # === Own ports ===

  boost159 = pkgs.callPackage ./boost/1.59.nix { };
  boost160 = pkgs.callPackage ./boost/1.60.nix { };
  busybox = pkgs.callPackage ./busybox { };

  cacert = pkgs.callPackage ./cacert.nix { };
  check-journal = pkgs.callPackage ./check-journal.nix { };
  clamav = pkgs.callPackage ./clamav.nix { };
  collectd = pkgs.callPackage ./collectd {
    libsigrok = null;
    libvirt = null;
    lm_sensors = null;  # probably not seen on VMs
    lvm2 = null;        # dito
  };
  collectdproxy = pkgs.callPackage ./collectdproxy { };
  coturn = pkgs.callPackage ./coturn { libevent = libevent.override {
    withOpenSSL = true;
    };};
  cron = pkgs.callPackage ./cron.nix { };
  curl = pkgs.callPackage ./curl rec {
    fetchurl = stdenv.fetchurlBoot;
    zlibSupport = true;
    sslSupport = true;
    scpSupport = true;
  };

  dnsmasq = pkgs.callPackage ./dnsmasq.nix { };
  docsplit = pkgs.callPackage ./docsplit { };

  easyrsa3 = pkgs.callPackage ./easyrsa { };
  electron = pkgs.callPackage ./electron.nix {
    gconf = pkgs.gnome.GConf;
  };
  expat = pkgs.callPackage ./expat.nix { };

  fcbox = pkgs.callPackage ./fcbox { };
  fcmaintenance = pkgs.callPackage ./fcmaintenance { };
  fcmanage = pkgs.callPackage ./fcmanage { };
  fcsensuplugins = pkgs.callPackage ./fcsensuplugins { };
  fcuserscan = pkgs.callPackage ./fcuserscan.nix { };
  fclogcheckhelper = pkgs.callPackage ./fclogcheckhelper { };
  fix-so-rpath = pkgs.callPackage ./fix-so-rpath {};

  grafana = pkgs_17_09.callPackage ./grafana { };
  graylog = pkgs.callPackage ./graylog { };
  graylogPlugins = pkgs.recurseIntoAttrs (
      pkgs.callPackage graylog/plugins.nix { }
    );

  http-parser = pkgs.callPackage ./http-parser {
    gyp = pkgs.pythonPackages.gyp;
  };

  imagemagick = imagemagickBig.override {
    ghostscript = null;
  };
  imagemagickBig = pkgs.callPackage ./ImageMagick { };

  influxdb = pkgs.callPackage ./influxdb.nix { };
  innotop = pkgs.callPackage ./percona/innotop.nix { };

  libevent = pkgs.callPackage ./libevent.nix { };
  libidn = pkgs.callPackage ./libidn.nix { };
  libreoffice = libreoffice-fresh;

  linux = linux_4_4;
  linux_4_4 = pkgs.callPackage ./kernel/linux-4.4.nix {
    kernelPatches = [ pkgs.kernelPatches.bridge_stp_helper ];
  };
  linuxPackages = linuxPackages_4_4;
  linuxPackages_4_4 =
    # This is hacky, but works for now. linuxPackagesFor is intended to
    # automatically customize for each kernel but making that overridable
    # is beyond my comprehension right now.
    let
      default_pkgs = pkgs.recurseIntoAttrs
      (pkgs.linuxPackagesFor linux_4_4 linuxPackages_4_4);
    in
      overrideExisting default_pkgs { inherit virtualbox virtualboxGuestAdditions; };

  mc = pkgs.callPackage ./mc.nix { };
  mariadb = pkgs.callPackage ./mariadb.nix { };
  mailx = pkgs.callPackage ./mailx.nix { };
  memcached = pkgs.callPackage ./memcached.nix { };
  mongodb = mongodb_3_0;
  mongodb_3_0 = pkgs.callPackage ./mongodb/3_0.nix {
    sasl = pkgs.cyrus_sasl;
  };
  mongodb_3_2 = pkgs.callPackage ./mongodb {
    sasl = pkgs.cyrus_sasl;
  };
  multiping = pkgs.callPackage ./multiping { };

  nagiosPluginsOfficial = pkgs.callPackage ./nagios-plugins-official-2.x.nix {};
  nfs-utils = pkgs_17_09.nfs-utils.overrideAttrs (old: {
    postInstall = old.postInstall + "\nln -s bin $out/sbin\n";
  });
  nginx =
    let
      nginxModules = import ./nginx/modules.nix { inherit pkgs; };
    in
    pkgs.callPackage ./nginx/stable.nix {
      modules = [ nginxModules.rtmp nginxModules.dav nginxModules.moreheaders ];
    };

  nodejs4 = nodejs-4_x;
  nodejs6 = nodejs-6_x;
  nodejs8 = nodejs-8_x;
  nodejs9 = nodejs-9_x;

  inherit (pkgs.callPackage ./nodejs { libuv = pkgs.libuvVersions.v1_9_1; })
    nodejs7;

  inherit (pkgs.callPackages ./openssl {
      fetchurl = pkgs.fetchurlBoot;
      cryptodevHeaders = pkgs.linuxPackages.cryptodev.override {
        fetchurl = pkgs.fetchurlBoot;
        onlyHeaders = true;
      };
    })
    openssl_1_0_2 openssl_1_1_0 ;
  openssl = openssl_1_0_2;

  # We don't want anyone to still use openssl 1.0.1 so I'm putting this in as
  # a null value to break any dependency explicitly.
  openssl_1_0_1 = null;

  osm2pgsql = pkgs.callPackage ./osm2pgsql.nix { };
  osrm-backend = pkgs.callPackage ./osrm-backend { };

  pcre = pkgs.callPackage ./pcre.nix { };
  pcre-cpp = pcre.override { variant = "cpp"; };
  percona = percona57;
  percona57 = pkgs.callPackage ./percona/5.7.nix { boost = boost159; };
  percona56 = pkgs.callPackage ./percona/5.6.nix { boost = boost159; };
  percona-toolkit = pkgs.callPackage ./percona/toolkit.nix { };

  postgis = pkgs.callPackage ./postgis { };
  inherit (pkgs.callPackages ./postgresql { })
    postgresql93
    postgresql94
    postgresql95
    postgresql96;

  rum = pkgs.callPackage ./postgresql/rum { postgresql = postgresql96; };

  inherit (pkgs.callPackages ./php { })
    php55;
  phpPackages = php56Packages;

  postfix = pkgs.callPackage ./postfix/3.0.nix { };
  powerdns = pkgs.callPackage ./powerdns.nix { };
  prometheus-elasticsearch-exporter = pkgs_17_09.callPackage ./prometheus-elasticsearch-exporter.nix { };

  qemu = pkgs.callPackage ./qemu/qemu-2.8.nix {
    inherit (pkgs.darwin.apple_sdk.frameworks) CoreServices Cocoa;
    x86Only = true;
  };
  qpress = pkgs.callPackage ./percona/qpress.nix { };

  rabbitmq_server_3_6_5 = pkgs.callPackage ./rabbitmq/server-3.6.5.nix { };
  rabbitmq_server_3_6_15 = pkgs.callPackage ./rabbitmq/server-3.6.15.nix { };
  rabbitmq_server = rabbitmq_server_3_6_15;

  rabbitmq_delayed_message_exchange =
    pkgs.callPackage ./rabbitmq/delayed_message_exchange.nix { };

  rust = pkgs.callPackage ./rust/default.nix { };
  rustPlatform = pkgs.recurseIntoAttrs (makeRustPlatform rust);
  makeRustPlatform = rust: fix (self:
    let
      callPackage = pkgs.newScope self;
    in rec {
      inherit rust;

      rustRegistry = pkgs.callPackage ./rust/rust-packages.nix { };

      buildRustPackage = pkgs.callPackage ./rust/buildRustPackage.nix {
        inherit rust rustRegistry;
      };
    });
  rustfmt = pkgs.callPackage ./rust/rustfmt.nix { };

  # compatibility fixes for 15.09
  rustCargoPlatform = rustPlatform;
  rustStable = rustPlatform;
  rustUnstable = rustPlatform;

  sensu = pkgs.callPackage ./sensu {
    ruby = pkgs.ruby_2_1;
  };

  subversion = subversion18;

  telegraf = pkgs.callPackage ./telegraf {
    inherit (pkgs_17_09) buildGoPackage fetchFromGitHub;
  };

  uchiwa = pkgs.callPackage ./uchiwa { };

  varnish =
    (pkgs.callPackage ../../../../pkgs/servers/varnish { }).overrideDerivation
    (old: {
      buildFlags = "localstatedir=/var/spool";
    });
  # The guest additions need to use the kernel we're actually building so we
  # have to callPackage them instead of using the pre-made package.
  virtualboxGuestAdditions = pkgs_17_09.callPackage "${pkgs_17_09_src}/pkgs/applications/virtualization/virtualbox/guest-additions" { kernel = linux_4_4; };
  vulnix = pkgs.callPackage ./vulnix { };

  xtrabackup = pkgs.callPackage ./percona/xtrabackup.nix { };

  yarn = pkgs.callPackage ./yarn.nix { nodejs = nodejs7; };

}
