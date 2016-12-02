{ lib, ... }:

{

  imports = [
    ./percona
  ];

  nixpkgs.config.packageOverrides = pkgs: rec {

    boost159 = pkgs.callPackage ./boost-1.59.nix { };

    cron = pkgs.callPackage ./cron.nix { };

    dnsmasq = pkgs.callPackage ./dnsmasq.nix { };

    easyrsa3 = pkgs.callPackage ./easyrsa { openssl = pkgs.openssl_1_0_2; };

    fcmaintenance = pkgs.callPackage ./fcmaintenance { };
    fcmanage = pkgs.callPackage ./fcmanage { };
    fcsensuplugins = pkgs.callPackage ./fcsensuplugins { };
    fcutil = pkgs.callPackage ./fcutil { };

    linux_4_4 = pkgs.callPackage ./linux-4.4.nix {
      kernelPatches =
        [ pkgs.kernelPatches.bridge_stp_helper
        ]
        ++ pkgs.lib.optionals ((pkgs.platform.kernelArch or null) == "mips")
        [ pkgs.kernelPatches.mips_fpureg_emu
          pkgs.kernelPatches.mips_fpu_sigill
          pkgs.kernelPatches.mips_ext3_n32
        ];
      extraConfig =  ''
          IP_MULTIPLE_TABLES y
          IPV6_MULTIPLE_TABLES y
          LATENCYTOP y
          SCHEDSTATS y
          '';
    };

    linuxPackages_4_4 = pkgs.recurseIntoAttrs
      (pkgs.linuxPackagesFor linux_4_4 linuxPackages_4_4);

    mc = pkgs.callPackage ./mc.nix { };
    mailx = pkgs.callPackage ./mailx.nix { };
    mongodb32 = pkgs.callPackage ./mongodb { sasl = pkgs.cyrus_sasl; };
    graylog = pkgs.callPackage ./graylog.nix { };

    nagiosplugin = pkgs.callPackage ./nagiosplugin.nix { };

    osm2pgsql = pkgs.callPackage ./osm2pgsql.nix { };

    postfix = pkgs.callPackage ./postfix/3.0.nix { };
    powerdns = pkgs.callPackage ./powerdns.nix { };
    pypkgs = pkgs.callPackage ./pypkgs.nix { };

    qemu = pkgs.callPackage ./qemu-2.5.nix {
      inherit (pkgs.darwin.apple_sdk.frameworks) CoreServices Cocoa;
      x86Only = true;
    };

    sensu = pkgs.callPackage ./sensu { };
    uchiwa = pkgs.callPackage ./uchiwa { };

    vulnix = pkgs.callPackage ./vulnix { };

    rabbitmq_delayed_message_exchange =
      pkgs.callPackage ./rabbitmq_delayed_message_exchange.nix { };

    elasticsearch2 = pkgs.callPackage ./elasticsearch2 { };
    elasticsearchPlugins = lib.recurseIntoAttrs (
      pkgs.callPackage ./elasticsearch/plugins.nix { }
    );

    nodejs6 = pkgs.callPackage ./nodejs6/default.nix {
      libuv = pkgs.libuvVersions.v1_9_1;
      openssl = pkgs.openssl_1_0_2;
    };

  };
}
