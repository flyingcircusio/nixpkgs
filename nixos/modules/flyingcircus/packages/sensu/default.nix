{ lib, bundlerEnv, ruby_2_0, python2, pkgs, which, defaultGemConfig, zlib, libxml2, graphicsmagick, pkgconfig, imagemagickBig }:

let
    pyenv = python2.buildEnv.override {
      extraLibs = with pkgs.python2Packages;
        [ pymongo ];
    } ;
in

bundlerEnv {
  name = "sensu-0.22.1";

  ruby = ruby_2_0;

  gemfile = ./Gemfile;
  lockfile = ./Gemfile.lock;
  gemset = ./gemset.nix;

  gemConfig = defaultGemConfig // {
    libxml-ruby = attrs: {
      buildInputs = [ zlib ];
      preInstall = ''
        bundle config build.libxml-ruby "--use-system-libraries --with-xml2-lib=${libxml2}/lib --with-xml2-include=${libxml2}/include/libxml2"
      '';
    };
    rmagick = attrs: {
      buildInputs = [ which graphicsmagick pkgconfig imagemagickBig ];
    };
    mysql = attrs: {
      buildInputs = with pkgs; [ mysql ];
    };
    redis = attrs: {
      buildInputs = with pkgs; [ redis ];
    };
    mongo = attrs: {
      buildInputs = with pkgs; [ mongodb ];
    };
    sensu-plugins-mongodb = attrs: {
      buildInputs = [ pyenv ];
      postPatch = ''
        # the ruby check runs a python script
        # patchShebangs bin/check-mongodb.py
        substituteInPlace bin/check-mongodb.py \
        --replace "#!/usr/bin/env python" "#!${pyenv}/bin/python"
      '';
    };
  };

  meta = with lib; {
    description = "A monitoring framework that aims to be simple, malleable, and scalable";
    homepage    = http://sensuapp.org/;
    license     = licenses.mit;
    maintainers = with maintainers; [ theuni ];
    platforms   = platforms.unix;
  };

}
