{ buildGoModule, lib, fetchFromGitLab, git }:

buildGoModule rec {
  pname = "gitlab-kas";
  version = "18.3.2";
  majorVersion = "v${lib.versions.major version}";
  # Gitlab wants to display the git commit ID in the Admin UI.
  gitRef = "04d831fd6688b49c23904ee6724b86badb381cb0";
  goPkgPath = "gitlab.com/gitlab-org/cluster-integration/gitlab-agent/${majorVersion}";

  # nixpkgs-update: no auto update
  src = fetchFromGitLab {
    owner = "gitlab-org";
    repo = "cluster-integration/gitlab-agent";
    rev = "${gitRef}";
    hash = "sha256-6haYjfYMgDpxBPb0GRLev+KQKM3Ic63P+YROaAVTahc=";
  };

  vendorHash = "sha256-MA3JTPCNJC49HhMMuxV3Fod36nh/8zWy/pv0h44rv54=";
  subPackages = [ "./cmd/kas" ];
  ldflags = [
    "-X ${goPkgPath}/internal/cmd.Version=${version}"
    "-X ${goPkgPath}/internal/cmd.GitRef=${gitRef}"
  ];

  meta = with lib; {
    description = "Kubernetes Agent (Gitlab side)";
    mainProgram = "gitlab-pages";
    homepage = "https://gitlab.com/gitlab-org/gitlab-pages";
    changelog = "https://gitlab.com/gitlab-org/gitlab-pages/-/blob/v${version}/CHANGELOG.md";
    license = licenses.mit;
  };
}
