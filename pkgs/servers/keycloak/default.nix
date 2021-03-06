{ stdenv, fetchzip, makeWrapper, jre }:

stdenv.mkDerivation rec {
  pname   = "keycloak";
  version = "13.0.1";

  src = fetchzip {
    url    = "https://github.com/keycloak/keycloak/releases/download/${version}/keycloak-${version}.zip";
    sha256 = "sha256-81i8Yf9rEuHtUDqYThUCn0/Lb9YokRi4tGi/Ooyyxr8=";
  };

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    mkdir $out
    cp -r * $out

    rm -rf $out/bin/*.{ps1,bat}
    rm -rf $out/bin/add-user-keycloak.sh
    rm -rf $out/bin/jconsole.sh

    chmod +x $out/bin/standalone.sh
    wrapProgram $out/bin/standalone.sh \
      --prefix PATH ":" ${jre}/bin ;
  '';

  meta = with stdenv.lib; {
    homepage    = "https://www.keycloak.org/";
    description = "Identity and access management for modern applications and services";
    license     = licenses.asl20;
    platforms   = jre.meta.platforms;
    maintainers = [ maintainers.ngerstle ];
  };

}
