{ stdenv, fetchurl, cmake, boost, bison, ncurses, openssl, readline, zlib, perl }:

# Note: zlib is not required; MySQL can use an internal zlib.

stdenv.mkDerivation rec {
  name = "percona-${version}";
  version = "5.6.30-76.3";

  src = fetchurl {
    url = "https://www.percona.com/downloads/Percona-Server-5.6/Percona-Server-${version}/source/tarball/percona-server-${version}.tar.gz";
    sha256 = "c762b6795b353ae9edecd2ccbb1b4a2677b04dd78ad760740a6a972b738f16cd";
  };

  preConfigure = stdenv.lib.optional stdenv.isDarwin ''
    ln -s /bin/ps $TMPDIR/ps
    export PATH=$PATH:$TMPDIR
  '';

  buildInputs = [ cmake bison ncurses openssl readline zlib boost ]
     ++ stdenv.lib.optional stdenv.isDarwin perl;

  enableParallelBuilding = true;

  cmakeFlags = [
    "-DWITH_SSL=yes"
    "-DWITH_EMBEDDED_SERVER=yes"
    "-DWITH_ZLIB=yes"
    "-DWITH_EDITLINE=bundled"
    "-DHAVE_IPV6=yes"
    "-DMYSQL_UNIX_ADDR=/run/mysqld/mysqld.sock"
    "-DMYSQL_DATADIR=/var/lib/mysql"
    "-DINSTALL_SYSCONFDIR=etc/mysql"
    "-DINSTALL_INFODIR=share/mysql/docs"
    "-DINSTALL_MANDIR=share/man"
    "-DINSTALL_PLUGINDIR=lib/mysql/plugin"
    "-DINSTALL_SCRIPTDIR=bin"
    "-DINSTALL_INCLUDEDIR=include/mysql"
    "-DINSTALL_DOCREADMEDIR=share/mysql"
    "-DINSTALL_SUPPORTFILESDIR=share/mysql"
    "-DINSTALL_MYSQLSHAREDIR=share/mysql"
    "-DINSTALL_DOCDIR=share/mysql/docs"
    "-DINSTALL_SHAREDIR=share/mysql"
  ];

  NIX_LDFLAGS = stdenv.lib.optionalString stdenv.isLinux "-lgcc_s";

  prePatch = ''
    sed -i -e "s|/usr/bin/libtool|libtool|" cmake/libutils.cmake
  '';
  postInstall = ''
    sed -i -e "s|basedir=\"\"|basedir=\"$out\"|" $out/bin/mysql_install_db
    rm -r $out/mysql-test
    rm $out/share/man/man1/mysql-test-run.pl.1
  '';

  passthru.mysqlVersion = "5.6";

  meta = {
    homepage = http://www.percona.com/;
    description = ''
      Is a free, fully compatible, enhanced, open source drop-in replacement for
      MySQL® that provides superior performance, scalability and instrumentation.
    '';
  };
}
