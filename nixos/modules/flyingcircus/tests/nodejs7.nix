import ../../../tests/make-test.nix ({ ... }:
{
  name = "nodejs7";

  nodes = {
    master =
      { pkgs, config, ... }:
      {

        imports = [
          ./setup.nix
          ../static/default.nix
          ../roles/default.nix
          ../services/default.nix
          ../platform/default.nix
        ];

        virtualisation.memorySize = 1024;
        environment.systemPackages = [
          pkgs.nodejs7
        ];
      };
  };

  testScript = ''
    startAll;

    $master->succeed('node -e \'console.log("ok")\' ');
  '';
})
