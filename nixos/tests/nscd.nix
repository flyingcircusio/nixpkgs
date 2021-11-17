import ./make-test-python.nix {
  name = "nscd";

  machine = { pkgs, ... }: {

      environment.systemPackages = [
        pkgs.python3Full
      ];
      services.dnsmasq = {
          enable = true;
          extraConfig = ''
            log-queries
            log-facility=-
            address=/example.com/127.0.0.1
          '';
      };
      networking.nameservers = [ "127.0.0.1" ];
  };

  testScript = ''
    machine.wait_for_unit("multi-user.target")
    print(
        machine.execute(
            "python -c 'import socket; socket.getaddrinfo(\"example.com\", 0, socket.AF_INET)'"
        )[1]
    )
    print("checking query log (1/2)")
    query_count = machine.execute("journalctl -u dnsmasq.service | grep -c example.com")[1]
    assert int(query_count) == 2
    print(
        machine.execute(
            "python -c 'import socket; socket.getaddrinfo(\"example.com\", 0, socket.AF_INET)'"
        )[1]
    )
    print("OK")
    print("checking query log (2/2)")
    query_count = machine.execute("journalctl -u dnsmasq.service | grep -c example.com")[1]
    assert int(query_count) == 4
    print("OK")
  '';
}
