{ lib, fclib, ... }:
with lib;
rec {

  # get the DN of this node for LDAP logins.
  getLdapNodeDN = config:
    "cn=${config.networking.hostName},ou=Nodes,dc=gocept,dc=com";

  # Compute LDAP password for this node.
  getLdapNodePassword = config:
    builtins.hashString "sha256" (concatStringsSep "/" [
      "ldap"
      config.flyingcircus.enc.parameters.directory_password
      config.networking.hostName
    ]);

  mkPlatform = lib.mkOverride 900;

  getServicePassword = {
      pkgs
      , file
      , user ? "root"
      , mode ? "0660"
    }:
    # XXX Is there a way to get pkgs here w/o passing?
    let
      identifier = builtins.replaceStrings ["/"] ["-"] file;
      generatedPassword = readFile
        (pkgs.runCommand identifier { preferLocalBuild = true; }
          "${pkgs.apg}/bin/apg -a 1 -M lnc -n 1 -m 32 -d > $out");

    in rec {
      activation = ''
        # Only install if not there, otherwise, permissions might change.
        test -d $(dirname ${file}) || install -d $(dirname ${file})
        if [[ ! -e ${file} ]]; then
          ( umask 007;
            echo -n ${generatedPassword} > ${file}
            chown ${user}:service ${file}
          )
        fi
          chmod ${mode} ${file}
        '';
      value = fclib.configFromFile file generatedPassword;
    };

}
