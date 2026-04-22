{
  stdenv,
  callPackage,
  sasl,
  boost,
  cctools,
  avxSupport ? stdenv.hostPlatform.avxSupport,
  nixosTests,
  lib,
}:

let
  buildMongoDB = callPackage ./mongodb.nix {
    inherit
      sasl
      boost
      cctools
      stdenv
      ;
  };
in
buildMongoDB {
  inherit avxSupport;
  version = "7.0.31";
  hash = "sha256-Vk/XsnYut0Hfad/X6LZw6gJX1NHc4/6XT8y1KehpLMk=";
  patches = [
    # ModuleNotFoundError: No module named 'mongo_tooling_metrics':
    # NameError: name 'SConsToolingMetrics' is not defined:
    # The recommended linker 'lld' is not supported with the current compiler configuration, you can try the 'gold' linker with '--linker=gold'.
    ./mongodb7-SConstruct.patch

    # Fix building with python 3.12 since the imp module was removed
    ./mongodb-python312.patch

    # mongodb-7_0's mozjs uses avx2 instructions
    # https://github.com/GermanAizek/mongodb-without-avx/issues/16
  ]
  ++ lib.optionals (!avxSupport) [ ./mozjs-noavx.patch ];
  postPatch = ''
    # fix environment variable reading
    substituteInPlace SConstruct \
        --replace-fail "env = Environment(" "env = Environment(ENV = os.environ,"
  ''
  + ''
    # Fix debug gcc 11 and clang 12 builds on Fedora
    # https://github.com/mongodb/mongo/commit/e78b2bf6eaa0c43bd76dbb841add167b443d2bb0.patch
    substituteInPlace src/mongo/db/query/plan_summary_stats.h --replace-fail '#include <string>' '#include <optional>
    #include <string>'
    substituteInPlace src/mongo/db/exec/plan_stats.h --replace-fail '#include <string>' '#include <optional>
    #include <string>'
  ''
  + lib.optionalString (!avxSupport) ''
    substituteInPlace SConstruct \
      --replace-fail "default=['+sandybridge']," 'default=[],'
  '';

  passthru.tests = {
    inherit (nixosTests) mongodb;
  };
}
