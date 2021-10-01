{ stdenv, fetchurl, writeText, nss, python3
, blacklist ? []
, includeEmail ? false
}:

with stdenv.lib;

let

  certdata2pem = fetchurl {
    name = "certdata2pem.py";
    urls = [
      "https://salsa.debian.org/debian/ca-certificates/raw/debian/20170717/mozilla/certdata2pem.py"
      "https://git.launchpad.net/ubuntu/+source/ca-certificates/plain/mozilla/certdata2pem.py?id=47e49e1e0a8a1ca74deda27f88fe181191562957"
    ];
    sha256 = "1d4q27j1gss0186a5m8bs5dk786w07ccyq0qi6xmd2zr1a8q16wy";
  };

in

stdenv.mkDerivation rec {
  name = "nss-cacert-${version}";
  version = "3.66";

  src = fetchurl {
    url = "mirror://mozilla/security/nss/releases/NSS_${replaceStrings ["."] ["_"] version}_RTM/src/nss-${version}.tar.gz";
    sha256 = "1jfdnh5l4k57r2vb07s06hqi7m2qzk0d9x25lsdsrw3cflx9x9w9";
  };

  nativeBuildInputs = [ python3 ];

  configurePhase = ''
    ln -s nss/lib/ckfw/builtins/certdata.txt

    cat << EOF > blacklist.txt
    ${concatStringsSep "\n" (map (c: ''"${c}"'') blacklist)}
    EOF

    cp ${certdata2pem} certdata2pem.py
    ${optionalString includeEmail ''
      # Disable CAs used for mail signing
      substituteInPlace certdata2pem.py --replace \[\'CKA_TRUST_EMAIL_PROTECTION\'\] '''
    ''}
  '';

  buildPhase = ''
    python3 certdata2pem.py | grep -vE '^(!|UNTRUSTED)'

    for cert in *.crt; do
      echo $cert | cut -d. -f1 | sed -e 's,_, ,g' >> ca-bundle.crt
      cat $cert >> ca-bundle.crt
      echo >> ca-bundle.crt
    done
  '';

  installPhase = ''
    mkdir -pv $out/etc/ssl/certs
    cp -v ca-bundle.crt $out/etc/ssl/certs
  '';

  meta = {
    homepage = http://curl.haxx.se/docs/caextract.html;
    description = "A bundle of X.509 certificates of public Certificate Authorities (CA)";
    platforms = platforms.all;
    maintainers = with maintainers; [ wkennington fpletz ];
  };
}
