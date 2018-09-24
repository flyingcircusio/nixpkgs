{ pkgs }:

(pkgs.callPackage
  ../../../../pkgs/servers/monitoring/nagios/plugins/official-2.x.nix { })
.overrideDerivation
  (old: {
    buildInputs = [ pkgs.openssh pkgs.perl ];
    nativeBuildInputs = [ pkgs.openldap ];
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
  })
