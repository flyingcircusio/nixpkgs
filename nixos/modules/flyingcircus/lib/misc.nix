{ lib, pkgs ? import <nixpkgs> {}, ...}:

rec {
  # returns a list with password and sha256sum of the password
  generatePasswordHash = {
    serviceName,
    length,
    passOnly ? false
    }:
    let passAndHash = lib.splitString " " (lib.readFile
      (pkgs.runCommand "${serviceName}.password" {}
        ''pass=$(${pkgs.apg}/bin/apg -a 1 -M lnc -n 1 -m ${toString length})
          hash=$(echo -n $pass | sha256sum | cut -f1 -d " ")
          echo -n "$pass $hash" > $out''
      ));
    in if passOnly then builtins.elemAt passAndHash 0
       else passAndHash;
  # returns only a password
  generatePassword = { serviceName, length }: generatePasswordHash {inherit serviceName length; passOnly = true;};
}
