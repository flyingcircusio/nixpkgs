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
    machine.wait_for_unit("nscd.service")
    machine.wait_for_unit("dnsmasq.service")
    machine.succeed("systemctl status nscd.service")
    machine.succeed("systemctl status dnsmasq.service")
    print(machine.execute("ls -lah `which nscd`")[1])
    print(machine.execute("netstat -npul")[1])
    print(
        machine.execute(
            "python -c 'import socket; socket.getaddrinfo(\"example.com\", 0, socket.AF_INET)'"
        )[1]
    )
    print("checking first query log")
    query_count = machine.execute("journalctl -u dnsmasq.service | grep -c example.com")[1]
    assert int(query_count) == 2
    print(
        machine.execute(
            "python -c 'import socket; socket.getaddrinfo(\"example.com\", 0, socket.AF_INET)'"
        )[1]
    )
    print("checking second query log")
    query_count = machine.execute("journalctl -u dnsmasq.service | grep -c example.com")[1]
    assert int(query_count) == 4
    print("Full dnsmasq log for debugging")
    print(machine.execute("journalctl -u dnsmasq.service")[1])
  '';
}
