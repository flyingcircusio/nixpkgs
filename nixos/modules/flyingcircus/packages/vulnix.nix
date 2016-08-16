{ pkgs ? import (builtins.fetchTarball https://github.com/NixOS/nixpkgs-channels/archive/453086a15fc0db0c2bc17d98350b0632551cb0fe.tar.gz) {},
}:

let
  vulnix_src = import (builtins.fetchTarball https://pypi.python.org/packages/bf/22/44c7b7e581b11d8bf30764a38f92b2a4fad5508ca9f19912da758236f97d/vulnix-1.1.3.tar.gz);
in
  vulnix_src { inherit pkgs; }
