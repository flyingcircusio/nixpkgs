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
      linux_4_3 = pkgs.linux_4_3.override {
        # This is currently specific to VMs.
        extraConfig = ''
          BALLOON_COMPACTION y
          BLK_DEV_DM y
          BLK_DEV_LOOP m
          COMPACTION y
          CONFIGFS_FS m
          CRYPTO_AES_NI_INTEL m
          CRYPTO_CRC32C_INTEL m
          CRYPTO_SHA256 y
          CRYPTO_SHA512 m
          DEBUG_FS y
          DEBUG_INFO y
          DEFAULT_SECURITY_APPARMOR y
          DM_SNAPSHOT m
          DMIID y
          E100 n
          EXT4_FS y
          EXT4_FS_POSIX_ACL y
          FDDI n
          FTRACE_SYSCALLS y
          FUNCTION_GRAPH_TRACER y
          FUNCTION_PROFILER y
          FUNCTION_TRACER y
          FUSE_FS m
          HANGCHECK_TIMER m
          HW_RANDOM_AMD n
          HW_RANDOM_VIA n
          HYPERVISOR_GUEST y
          I6300ESB_WDT y
          IKCONFIG y
          IKCONFIG_PROC y
          INET_DIAG m
          INET_UDP_DIAG m
          INPUT_MISC n
          INPUT_TABLET n
          INPUT_TOUCHSCREEN n
          INTEL_IDLE y
          IOSCHED_DEADLINE m
          IP_ADVANCED_ROUTER y
          IP_MULTICAST y
          IP_MULTIPLE_TABLES y
          IP_MULTIPLE_TABLES y
          IPV6 y
          IPV6_MULTIPLE_TABLES y
          IPV6_MULTIPLE_TABLES y
          KPROBES y
          KVM_GUEST y
          LATENCYTOP y
          MACINTOSH_DRIVERS n
          MD y
          NET_IPIP m
          NET_SCH_CODEL m
          NET_SCH_FQ m
          NET_SCH_FQ_CODEL m
          NET_SCH_PRIO m
          NETFILTER_ADVANCED y
          NETFILTER_XT_MATCH_HASHLIMIT m
          NETFILTER_XT_MATCH_IPRANGE m
          NETFILTER_XT_MATCH_LIMIT m
          NETFILTER_XT_MATCH_MARK m
          NETFILTER_XT_MATCH_MULTIPORT m
          NETFILTER_XT_MATCH_OWNER m
          NETFILTER_XT_MATCH_TCPMSS m
          NETWORK_FILESYSTEMS y
          NF_CONNTRACK m
          NFSD m
          NFSD_V4 y
          PACKET_DIAG m
          PARAVIRT y
          PARAVIRT_SPINLOCKS y
          RELAY y
          RFKILL n
          SCHEDSTATS y
          SCSI_LOWLEVEL y
          SECURITY_APPARMOR y
          SOFT_WATCHDOG m
          TCP_CONG_BIC m
          TCP_CONG_HTCP m
          TCP_CONG_ILLINOIS m
          TCP_CONG_VEGAS m
          TCP_CONG_WESTWOOD m
          TCP_CONG_YEAH m
          TRANSPARENT_HUGEPAGE y
          TUN m
          UNIX_DIAG m
          USB_PRINTER n
          USB_SERIAL m
          USB_SERIAL_FTDI_SIO m
          VIRTIO_BALLOON m
          VIRTIO_BLK y
          VIRTIO_MMIO m
          VIRTIO_NET m
          VIRTIO_PCI y
          WATCHDOG y
          XFS_FS y
          XFS_POSIX_ACL y
          XFS_QUOTA y
        '';
      };

      nagiosPluginsOfficial =
        pkgs.nagiosPluginsOfficial.overrideDerivation (oldAttrs: {
          buildInputs = [ pkgs.openssh pkgs.openssl pkgs.perl ];
          preConfigure= "
            configureFlagsArray=(
              --with-openssl=${pkgs.openssl}
              --with-ping-command='/var/setuid-wrappers/ping -n -w %d -c %d %s'
              --with-ping6-command='/var/setuid-wrappers/ping6 -n -w %d -c %d %s'
              # Don't add dependency to postfix or alike. If the test should
              # be run, some mailer daemon needs to be installed.
              --with-mailq-command=/run/current-system/sw/bin/mailq
            )
          ";
        });

      varnish =
        pkgs.varnish.overrideDerivation (old: {
          buildFlags = "localstatedir=/var/spool";
        });
    };

  };
}
