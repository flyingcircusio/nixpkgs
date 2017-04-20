{ config, pkgs, lib, ... }:

{
  config = {

    environment.systemPackages = with pkgs;
    [
        apacheHttpd
        atop
        bc
        bind
        bundler
        curl
        cyrus_sasl
        db
        dstat
        fcmaintenance
        file
        fio
        gcc
        gdbm
        git
        (gnupg.override{
          x11Support = false;
          pinentry = pkgs.pinentry.override {
            gtk2 = null;
            qt4 = null;
          };
        })
        go
        gptfdisk
        graphviz
        imagemagick
        iotop
        kerberos
        libjpeg
        libmemcached
        libxml2
        libxslt
        links
        lsof
        lynx
        mercurial
        mmv
        nano
        nc6
        ncdu
        netcat
        ngrep
        nmap
        nodejs
        openldap
        openssl_1_0_2
        php
        protobuf
        psmisc
        pv
        python2Full
        pythonPackages.virtualenv
        python34
        screen
        strace
        subversion
        sysstat
        tcpdump
        telnet
        traceroute
        tree
        unzip
        vim
        vulnix
        wget
        xfsprogs
        zlib
    ] ++
    lib.optional (!config.services.postgresql.enable) pkgs.postgresql;

  };
}
