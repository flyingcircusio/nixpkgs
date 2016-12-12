{ pkgs, ... }:

{
  config = {

    environment.systemPackages = with pkgs; [
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
        gnupg
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
        openssl
        php
        postgresql
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
    ];

    nixpkgs.config.packageOverrides = pkgs: {

      collectd = pkgs.collectd.override { libvirt = null; };

      nagiosPluginsOfficial =
        pkgs.nagiosPluginsOfficial.overrideDerivation (old: {
          buildInputs = [ pkgs.openssh pkgs.openssl pkgs.perl ];
          preConfigure= ''
            configureFlagsArray=(
              --with-openssl=${pkgs.openssl}
              --with-ping-command='/var/setuid-wrappers/ping -n -w %d -c %d %s'
              --with-ping6-command='/var/setuid-wrappers/ping6 -n -w %d -c %d %s'
              # Don't add dependency to postfix or alike. If the test should
              # be run, some mailer daemon needs to be installed.
              --with-mailq-command=/run/current-system/sw/bin/mailq
            )
          '';
        });

      varnish =
        pkgs.varnish.overrideDerivation (old: {
          buildFlags = "localstatedir=/var/spool";
        });

    };

  };
}
