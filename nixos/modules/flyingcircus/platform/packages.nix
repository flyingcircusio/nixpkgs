{ config, pkgs, lib, ... }:

{
  config = {

    environment.systemPackages = with pkgs; [
        apacheHttpd
        atop
        automake
        bc
        bind
        bundler
        cmake
        curl
        cyrus_sasl
        db
        dstat
        fclogcheckhelper
        fcuserscan
        file
        fio
        fix-so-rpath
        gcc
        gdb
        gdbm
        git
        gnumake
        gnupg
        go
        gptfdisk
        graphviz
        htop
        imagemagick
        iotop
        jq
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
        pkgconfig
        protobuf
        psmisc
        pv
        pwgen
        python2Full
        python34
        python36
        virtualenv_16
        ripgrep
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
        wget
        xfsprogs
        zlib
    ] ++
    lib.optional (!config.services.postgresql.enable) pkgs.postgresql;

  };
}
