{ lib, fetchFromGitLab, git, buildGoModule }:
let
  data = (builtins.fromJSON (builtins.readFile ../data.json));
in
buildGoModule rec {
  pname = "gitlab-workhorse";

  version = "13.8.8";

  src = fetchFromGitLab {
    owner = data.owner;
    repo = data.repo;
    rev = data.rev;
    sha256 = data.repo_hash;
  };

  sourceRoot = "source/workhorse";

  vendorSha256 = "0vkw12w7vr0g4hf4f0im79y7l36d3ah01n1vl7siy94si47g8ir5";
  buildInputs = [ git ];
  buildFlagsArray = "-ldflags=-X main.Version=${version}";
  doCheck = false;

  meta = with lib; {
    homepage = "http://www.gitlab.com/";
    platforms = platforms.linux;
    maintainers = with maintainers; [ fpletz globin talyz ];
    license = licenses.mit;
  };
}
