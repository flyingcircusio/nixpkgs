{ ... }:

{
  nixpkgs.config.packageOverrides = pkgs: rec {

    innotop = pkgs.callPackage ./innotop.nix { };

    percona57 = pkgs.callPackage ./5.7.nix {
      boost = (pkgs.callPackage ../boost-1.59.nix {});
    };

    percona56 = pkgs.callPackage ./5.6.nix {
      boost = (pkgs.callPackage ../boost-1.59.nix {});
    };

    percona = percona57;

    qpress = pkgs.callPackage ./qpress.nix { };
    xtrabackup = pkgs.callPackage ./xtrabackup.nix { };

  };
}
