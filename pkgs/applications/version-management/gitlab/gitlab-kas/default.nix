{ buildGoModule, lib, fetchFromGitLab }:

buildGoModule rec {
  pname = "gitlab-kas";
  version = "17.6.2";

  # nixpkgs-update: no auto update
  src = fetchFromGitLab {
    owner = "gitlab-org";
    repo = "cluster-integration/gitlab-agent";
    rev = "v${version}";
    hash = "sha256-3pmwChVdJ9wC/hN18ELvjc6GZ3jlz4PqzObSOlnppGk=";
  };

  vendorHash = "sha256-i8lNl5s5ZwdFcpj1zyEjgWczzKIvIeg5XFmbeNRFomo=";
  subPackages = [ "./cmd/kas" ];

  meta = with lib; {
    description = "Kubernetes Agent (Gitlab side)";
    mainProgram = "gitlab-pages";
    homepage = "https://gitlab.com/gitlab-org/gitlab-pages";
    changelog = "https://gitlab.com/gitlab-org/gitlab-pages/-/blob/v${version}/CHANGELOG.md";
    license = licenses.mit;
  };
}
