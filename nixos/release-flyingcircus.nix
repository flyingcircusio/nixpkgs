# This jobset is used to generate a NixOS channel that contains a
# small subset of Nixpkgs, mostly useful for servers that need fast
# security updates.
fdsajlkfdsa

{ nixpkgs ? { outPath = ./..; revCount = 56789; shortRev = "gfedcba"; }
, stableBranch ? false
, supportedSystems ? [ "x86_64-linux" ] # no i686-linux
, buildImage ? true
, buildInstaller ? false  # unused here
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

  # Prebuild packages listed below since they will be needed on VMs but are not
  # mentioned anywhere else here. Even better than listing packages here is to
  # write tests.
  preBuild = with pkgs; {
    inherit
      libreoffice
      libsodium
      openvpn
      qt4
      ssmtp
      wkhtmltopdf
      osrm-backend
      osm2pgsql
      ;
  };

  # List of package names for Python packages defined in modules/flyingcircus
  ownPythonPackages = builtins.attrNames
    (import modules/flyingcircus/packages/python-packages.nix {
      inherit pkgs stdenv;
      python = null; self = null; buildPythonPackage = a: {};
    });

  # pull only those derivations which are mentioned in pkgList
  filterPkgs = pkgList: pkgs:
    let
      # select relevant packages from pkgsList parameter
      p = lib.attrVals pkgList pkgs;
    in
    # assemble attrset
    builtins.listToAttrs
      (lib.zipListsWith (fst: snd: lib.nameValuePair fst snd) pkgList p);

in rec {
  nixos = {
    inherit (nixos') channel;
    tests = {
      inherit (nixos'.tests)
        firewall
        ipv6
        misc
        nat
        nfs4

        openssh
        proxy
        simple;

      flyingcircus = (import modules/flyingcircus/tests {
        inherit pkgs lib system hydraJob;
      });

      networking.scripted = {
        inherit (nixos'.tests.networking.scripted)
          static
          dhcpSimple
          dhcpOneIf
          sit
          vlan;
      };
    };
  };

  nixpkgs = lib.filterAttrs
    (n: v: lib.isDerivation v)
    (import modules/flyingcircus/packages/all-packages.nix { inherit pkgs; })
    // {
      python27Packages =
        filterPkgs ownPythonPackages nixpkgs'.python27Packages;
      python34Packages =
        filterPkgs ownPythonPackages nixpkgs'.python34Packages;
    } //
    preBuild;

  tested = lib.hydraJob (pkgs.releaseTools.aggregate {
    name = "nixos-${nixos.channel.version}";
    meta = {
      description = "Release-critical builds for the NixOS channel";
      maintainers = [ lib.maintainers.theuni ];
    };
    constituents =
      (lib.collect lib.isDerivation nixpkgs)
      ++ (lib.collect lib.isDerivation nixos)
      ++ (if buildImage then [flyingcircus_vm_image] else []);
  });

} //
lib.optionalAttrs buildImage { inherit flyingcircus_vm_image; }
