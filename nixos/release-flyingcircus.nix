# This jobset is used to generate a NixOS channel that contains a
# small subset of Nixpkgs, mostly useful for servers that need fast
# security updates.

{ nixpkgs ? { outPath = ./..; revCount = 56789; shortRev = "gfedcba"; }
, stableBranch ? false
, supportedSystems ? [ "x86_64-linux" ] # no i686-linux
, buildImage ? true
, buildInstaller ? true
}:

with import ../lib;

let

  nixpkgsSrc = nixpkgs; # urgh

  pkgs = import ./.. {};

  system = "x86_64-linux";

  lib = pkgs.lib;

  nixos' = import ./release.nix {
    inherit stableBranch supportedSystems;
    nixpkgs = nixpkgsSrc;
  };

  nixpkgs' = builtins.removeAttrs (import ../pkgs/top-level/release.nix {
    inherit supportedSystems;
    nixpkgs = nixpkgsSrc;
  }) [ "unstable" ];

  forAllSystems = lib.genAttrs supportedSystems;

  versionModule =
    { system.nixosVersionSuffix = versionSuffix;
      system.nixosRevision = nixpkgs.rev or nixpkgs.shortRev;
    };

  version = builtins.readFile ../.version;
  versionSuffix =
    (if stableBranch then "." else "pre") + "${toString (nixpkgs.revCount - 67824)}.${nixpkgs.shortRev}";

  # A bootable Flying Circus disk image (raw) that can be extracted onto
  # Ceph RBD volume.
  flyingcircus_vm_image =
    with import nixpkgsSrc { inherit system; };
    with lib;
    let
      config = (import lib/eval-config.nix {
        inherit system;
        modules = [ versionModule
                   ./modules/flyingcircus
                   ./modules/flyingcircus/imaging/vm.nix ];
      }).config;
    in
      # Declare the image as a build product so that it shows up in Hydra.
      hydraJob (runCommand "nixos-flyingcircus-vm-${config.system.nixosVersion}-${system}"
        { meta = {
            description = "NixOS Flying Circus VM bootstrap image (${system})";
            maintainers = maintainers.theuni;
          };
          image = config.system.build.flyingcircusVMImage;
        }
        ''
          mkdir -p $out/nix-support
          echo "file raw $image/image.qcow2.bz2" >> $out/nix-support/hydra-build-products
          ln -s $image/image.qcow2.bz2 $out/
        '');

  flyingcircus_vm_image_build =
    if buildImage
    then { flyingcircus_vm_image = flyingcircus_vm_image; }
    else {};

  installer = {
    inherit (nixos'.tests.installer)
      lvm
      separateBoot
      simple;
  };

  installer_build =
    if buildInstaller
    then { installer = installer; }
    else {};

in rec {
  nixos = {
    inherit (nixos')
      channel
      dummy;
    tests = {
      inherit (nixos'.tests)
        containers
        firewall
        ipv6
        login
        misc
        nat
        nfs3
        nfs4
        mysql

        postgresql
        openssh
        proxy
        simple;

      flyingcircus = {
            percona-57 = hydraJob
              (import modules/flyingcircus/tests/percona.nix {
                  percona = pkgs.callPackage
                    ./modules/flyingcircus/packages/percona/5.7.nix {
                      boost = (pkgs.callPackage ./modules/flyingcircus/packages/boost-1.59.nix {});
                    };
                  inherit system; }
            );
            percona-56 = hydraJob
              (import modules/flyingcircus/tests/percona.nix {
                  percona = pkgs.callPackage
                    ./modules/flyingcircus/packages/percona/5.6.nix {
                      boost = (pkgs.callPackage ./modules/flyingcircus/packages/boost-1.59.nix {});
                    };
                  inherit system; }
            );
            mysql-55 = hydraJob
              (import modules/flyingcircus/tests/percona.nix {
                  percona = pkgs.mysql55;
                  inherit system; }
            );
            sensuserver = hydraJob
              (import modules/flyingcircus/tests/sensu.nix {
                  inherit system; }
            );
      };

      networking.scripted = {
        inherit (nixos'.tests.networking.scripted)
          static
          dhcpSimple
          dhcpOneIf
          bond
          bridge
          # macvlan tests regularly get stuck and we don't use macvlan.
          # at the moment
          # scripted.macvlan
          sit
          vlan;
      };

      latestKernel = {
        inherit (nixos'.tests.latestKernel)
          login;
      };
    };
  }
  // installer_build;

  nixpkgs = {
    inherit (nixpkgs')
      apacheHttpd_2_4
      cmake
      collectd
      cryptsetup
      emacs
      gettext
      git
      imagemagick
      jdk
      linux
      mysql51
      mysql55
      nginx
      nodejs
      openssh
      php
      php55
      postgresql92
      postgresql93
      postgresql94
      python
      rsyslog
      stdenv
      subversion
      tarball
      varnish
      vim;

      influxdb011 = pkgs.callPackage ./modules/flyingcircus/packages/influxdb.nix { };
      mongodb32 = pkgs.callPackage ./modules/flyingcircus/packages/mongodb {
        sasl = pkgs.cyrus_sasl;
      };
      postfix = pkgs.callPackage ./modules/flyingcircus/packages/postfix/3.0.nix { };
      powerdns = pkgs.callPackage ./modules/flyingcircus/packages/powerdns.nix { };

      nodejs6 = pkgs.callPackage ./nodejs6/default.nix {
        libuv = pkgs.libuvVersions.v1_9_1;
        openssl = pkgs.openssl_1_0_2;
      };
  };

  tested = lib.hydraJob (pkgs.releaseTools.aggregate {
    name = "nixos-${nixos.channel.version}";
    meta = {
      description = "Release-critical builds for the NixOS channel";
      maintainers = [ lib.maintainers.theuni ];
    };
    constituents =
      let all = x: map (system: x.${system}) supportedSystems; in
      [ nixpkgs.tarball
        (all nixpkgs.jdk)
      ]
      ++ lib.collect lib.isDerivation nixos
      ++ (if buildImage
         then [flyingcircus_vm_image]
         else []);
  });

}
// flyingcircus_vm_image_build
