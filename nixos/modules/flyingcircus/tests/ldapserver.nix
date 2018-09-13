import ../../../tests/make-test.nix ({ pkgs, ... }:
let 
    suffix = "dc=example,dc=com";
in {
  name = "ldapserver";
  machine =
  { config, lib, ... }:
  {
    imports = [
      ./setup.nix
      ../platform
      ../roles
      ../services
      ../static
    ];

    flyingcircus.roles.ldapserver.enable = true;
    flyingcircus.roles.ldapserver.suffix = suffix;

  };

  testScript = ''
    $machine->start;
    $machine->waitForUnit("openldap");

    $machine->succeed(<<__TEST__);
      ${pkgs.nagiosPluginsOfficial}/bin/check_ldap \\
          -3 -H localhost -w 2 -c 4 -b ${suffix} \\
          -D cn=Reader,${suffix} \\
          -P "\$(< /etc/local/ldapserver/password.reader)" -4
    __TEST__

    $machine->succeed(<<__TEST__);
      ${pkgs.nagiosPluginsOfficial}/bin/check_ldap \\
          -3 -H localhost -w 2 -c 4 -b ${suffix} \\
          -D cn=Manager,${suffix} \\
          -P "\$(< /etc/local/ldapserver/password.manager)" -6
    __TEST__

  '';
})

