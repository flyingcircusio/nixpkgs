/*
 * library of local helper functions for use within modules.flyingcircus
 */

let
  lib = import <nixpkgs/lib>;
  network = import ./network.nix { inherit lib; };
  math = import ./math.nix { inherit lib; };
  system = import ./system.nix { inherit lib fclib; };
  files = import ./files.nix { inherit lib fclib; };
  utils = import ./utils.nix { inherit lib fclib; };

  fclib =
    { inherit network math system files utils; }
    // network // math // system // files // utils;

in
  fclib
