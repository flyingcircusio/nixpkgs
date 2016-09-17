{ pkgs, ...  }:

let
  vulnix = pkgs.fetchFromGitHub {
    rev = "bbc962fb0e1a3beec9eaa3198441f2e82e6ee418";
    owner = "flyingcircusio";
    repo = "vulnix";
    sha256 = "196mzbhvdmx7qmw8nc7yhhzdjz8mm4ir84lpr4lllxads7c81h8l";
  };
in
import vulnix { inherit pkgs; }
