{ fetchurl, pkgs ? import <nixpkgs> {} }:

let
  python = import ./requirements.nix { inherit pkgs; };
  version = "1.1.1";
in python.mkDerivation rec {
  name = "vulnix-${version}";
  src = fetchurl {
      url = "https://pypi.python.org/packages/5d/54/927b99e918224c767fdf8f5ac053fe20c20c44d25e22d30c3b5044077f29/${name}.tar.gz";
      sha256 = "0f6nxqh4mc4jqyw10dqcdzsxdfhlq4arsbsx8f0q4gly19b6ix7a";
    };
  # TODO: improve on internal and external dependencies
  buildInputs = [
    python.pkgs.flake8
    python.pkgs.pytest
    python.pkgs."pytest-cache"
    python.pkgs."pytest-capturelog"
    python.pkgs."pytest-codecheckers"
    python.pkgs."pytest-cov"
    python.pkgs."pytest-timeout"
  ];
   propagatedBuildInputs = [
    python.pkgs."click"
    python.pkgs."colorama"
    python.pkgs."PyYAML"
    python.pkgs."requests"
  ];
  doCheck = false;

  meta = with pkgs.lib; {
    homepage = https://github.com/flyingcircusio/vulnix;
    description = "vulnerability scanner for nix";
  };
}
