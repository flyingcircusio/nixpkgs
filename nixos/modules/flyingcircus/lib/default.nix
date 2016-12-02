/*
 * library of local helper functions for use within modules.flyingcircus
 */

let
  lib = import <nixpkgs/lib>;
  network = import ./network.nix { inherit lib; };
  math = import ./math.nix { inherit lib; };
  system = import ./system.nix { inherit lib fclib; };
  files = import ./files.nix { inherit lib fclib; };
  pkgs = import <nixpkgs> {};
  misc = import ./misc.nix { inherit pkgs lib; };

  fclib =
    { inherit network math system files; }
    // network // math // system // files // misc;

in
  fclib
