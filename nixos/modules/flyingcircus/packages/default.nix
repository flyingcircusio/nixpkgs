{ ... }:

{

  imports = [
    ./percona
  ];

  nixpkgs.config.packageOverrides = pkgs: with pkgs; rec {


    boost159 = callPackage ./boost-1.59.nix { };

    cron = callPackage ./cron.nix { };

    easyrsa3 = callPackage ./easyrsa { };

    fcmaintenance = callPackage ./fcmaintenance { };
    fcmanage = callPackage ./fcmanage { };
    fcsensuplugins = callPackage ./fcsensuplugins { };
    fcutil = callPackage ./fcutil { };

    nagiosplugin = callPackage ./nagiosplugin.nix { };

    powerdns = callPackage ./powerdns.nix { };
    pypkgs = callPackage ./pypkgs.nix { };

    qemu = callPackage ./qemu-2.5.nix {
      inherit (darwin.apple_sdk.frameworks) CoreServices Cocoa;
      x86Only = true;
    };

    sensu = callPackage ./sensu { };
    uchiwa = callPackage ./uchiwa { };

    mc = callPackage ./mc.nix { };

    osm2pgsql = callPackage ./osm2pgsql.nix { };

    vulnix = import (builtins.fetchTarball https://github.com/flyingcircusio/vulnix/archive/v1.0.tar.gz) { };

  };
}
