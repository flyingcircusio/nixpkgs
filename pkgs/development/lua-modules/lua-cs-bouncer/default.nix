{
  fetchFromGitHub,
  lua-resty-http,
  lua-cjson,
  buildLuaPackage,
  lua,
  lib,
}:
buildLuaPackage rec {
  pname = "lua-cs-bouncer";
  version = "1.0.19";

  src = fetchFromGitHub {
    owner = "crowdsecurity";
    repo = "lua-cs-bouncer";
    tag = "v${version}";
    hash = "sha256-SUIIt6cSGuGqAoMfM1DwBCeysrNgquBYecs1xtrH2og=";
  };

  outputs = [
    "out"
    "templates"
  ];

  propagatedBuildInputs = [
    lua-resty-http
    lua-cjson
  ];

  dontBuild = true;

  #
  patchPhase = ''
    substituteInPlace lib/crowdsec.lua --replace-fail 'require "plugins.crowdsec.' 'require "crowdsec.'
    for f in $(find lib/plugins/crowdsec -name '*.lua'); do
      echo $f
      substituteInPlace $f \
        --replace-quiet 'require "plugins.crowdsec.' 'require "crowdsec.'
      substituteInPlace $f \
        --replace-quiet "require 'plugins.crowdsec." "require 'crowdsec."
    done
  '';

  installPhase = ''
    mkdir -p $out/lib/lua/${lua.luaversion}/crowdsec
    cp lib/crowdsec.lua $out/lib/lua/${lua.luaversion}/crowdsec/init.lua
    cp lib/plugins/crowdsec/* $out/lib/lua/${lua.luaversion}/crowdsec

    cp -r templates $templates
  '';

  meta = {
    description = "Lua module to allow IP from CrowdSec API";
    homepage = "https://github.com/openresty/lua-resty-core";
    license = lib.licenses.mit;
    maintainers = [ lib.maintainers.leona ];
  };
}
