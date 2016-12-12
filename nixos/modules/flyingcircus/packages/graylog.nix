# backported from 16.03
{ stdenv, fetchurl }:

stdenv.mkDerivation rec {
  version = "2.1.1";
  name = "graylog-${version}";

  src = fetchurl {
    url = "https://packages.graylog2.org/releases/graylog/graylog-${version}.tgz";
    sha256 = "0p7vx6b4k6lzxi0v9x44wbrvplw93288lpixpwckc0xx0r7js07z";
  };

  src_sso = fetchurl {
    url= "https://github.com/Graylog2/graylog-plugin-auth-sso/releases/download/1.0.3/graylog-plugin-auth-sso-1.0.3.jar";
    sha256 ="1qraaf3pm2i7vhvrls9fspc6mxn9hf5n49298hza9rmhpc8izdzv";
  };

  src_logstash = fetchurl {
    url = "https://github.com/sivasamyk/graylog2-input-lumberjack/releases/download/v1.0.0/graylog2-input-lumberjack-1.0.0-rc1.jar";
    sha256 = "1854pvqw2ffgy7bhkk5savybwlvhlasxdpl1yph87znsyinzfrmr";
  };

  dontBuild = true;
  dontStrip = true;

  installPhase = ''
    mkdir -p $out
    cp -r {graylog.jar,lib,bin,plugin,data} $out
    cp ${src_sso.outPath} $out/plugin/
    cp ${src_logstash.outPath} $out/plugin/
  '';

  meta = with stdenv.lib; {
    description = "Open source log management solution";
    homepage    = https://www.graylog.org/;
    license     = licenses.gpl3;
    platforms   = platforms.unix;
    maintainers = [ maintainers.fadenb ];
  };
}
