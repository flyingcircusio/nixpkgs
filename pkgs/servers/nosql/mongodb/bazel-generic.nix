{
  lib,
  stdenv,
  buildBazelPackage,
  fetchFromGitHub,
  bazel_7,
  bash,
  buildPackages,
  boost,
  gperftools,
  snappy,
  zlib,
  yaml-cpp,
  sasl,
  net-snmp,
  openldap,
  openssl,
  libpcap,
  curl,
  cctools,
  xz,
  versionCheckHook,
}:

# Note:
#   The command line administrative tools are part of other packages:
#   see pkgs.mongodb-tools and pkgs.mongosh.

{
  version,
  hash,
  patches ? [ ],
  license ? lib.licenses.sspl,
  avxSupport ? stdenv.hostPlatform.avxSupport,
  passthru ? { },
}:

let
  scons = buildPackages.scons;
  python = scons.python.withPackages (
    ps: with ps; [
      pyyaml
      cheetah3
      psutil
      setuptools
      distutils
      packaging
      pymongo
    ]
  );

  system-libraries = [
    "boost"
    #pcre2 -- breaks on pcre2-10.46 with at least version 7.0.24
    "snappy"
    "yaml"
    "zlib"
    #"asio" -- XXX use package?
    #"stemmer"  -- not nice to package yet (no versioning, no makefile, no shared libs).
    #"valgrind" -- mongodb only requires valgrind.h, which is vendored in the source.
    #"wiredtiger"
  ]
  ++ lib.optionals stdenv.hostPlatform.isLinux [ "tcmalloc" ];
  inherit (lib) systems subtractLists;

in
buildBazelPackage rec {
  inherit version passthru;
  pname = "mongodb";

  src = fetchFromGitHub {
    owner = "mongodb";
    repo = "mongo";
    tag = "r${version}";
    inherit hash;
  };

  bazel = bazel_7;

  nativeBuildInputs = [
    bash
    python
  ]
  ++ lib.optional stdenv.hostPlatform.isLinux net-snmp;

  buildInputs = [
    boost
    curl
    gperftools
    libpcap
    yaml-cpp
    openssl
    openldap
    sasl
    snappy
    xz
    zlib
  ]
  ++ lib.optionals stdenv.hostPlatform.isDarwin [
    cctools
  ]
  ++ lib.optional stdenv.hostPlatform.isLinux net-snmp;

  # MongoDB keeps track of its build parameters, which tricks nix into
  # keeping dependencies to build inputs in the final output.
  # We remove the build flags from buildInfo data.
  inherit patches;

  env.NIX_CFLAGS_COMPILE = lib.optionalString stdenv.cc.isClang "-Wno-unused-command-line-argument";
  env.BAZELISK_SKIP_WRAPPER = "1";
  bazelTargets = [
    "install-mongod"
  ];

  #sconsFlags = [
  #  "--release"
  #  "--ssl"
  #  #"--rocksdb" # Don't have this packaged yet
  #  "--wiredtiger=on"
  #  "--js-engine=mozjs"
  #  "--use-sasl-client"
  #  "--disable-warnings-as-errors"
  #  "VARIANT_DIR=nixos" # Needed so we don't produce argument lists that are too long for gcc / ld
  #  "--link-model=static"
  #  "MONGO_VERSION=${finalAttrs.version}"
  #]
  #++ map (lib: "--use-system-${lib}") system-libraries;

  # This seems to fix mongodb not able to find OpenSSL's crypto.h during build
  #hardeningDisable = [ "fortify3" ];

  #preBuild = ''
  #  appendToVar sconsFlags "CC=$CC"
  #  appendToVar sconsFlags "CXX=$CXX"
  #''
  #+ lib.optionalString (!stdenv.hostPlatform.isDarwin) ''
  #  appendToVar sconsFlags "AR=$AR"
  #''
  #+ lib.optionalString stdenv.hostPlatform.isAarch64 ''
  #  appendToVar sconsFlags "CCFLAGS=-march=armv8-a+crc"
  #'';

  #preInstall = ''
  #  mkdir -p "$out/lib"
  #'';

  #postInstall = ''
  #  rm -f "$out/bin/install_compass" || true
  #'';
  #
  postPatch = ''
    patchShebangs tools/bazel
  '';
  fetchAttrs = {
    hash = "";
  };

  buildAttrs.installPhase = ''
    runHook preInstall

    exit 1

    runHook postInstall
  '';

  doInstallCheck = true;
  nativeInstallCheckInputs = [ versionCheckHook ];
  versionCheckProgram = "${placeholder "out"}/bin/mongo";
  versionCheckProgramArg = "--version";

  #installTargets = "install-devcore";

  #prefixKey = "DESTDIR=";

  enableParallelBuilding = true;

  meta = {
    description = "Scalable, high-performance, open source NoSQL database";
    homepage = "http://www.mongodb.org";
    inherit license;

    maintainers = [ ];
    platforms = subtractLists systems.doubles.i686 systems.doubles.unix;
  };
}
