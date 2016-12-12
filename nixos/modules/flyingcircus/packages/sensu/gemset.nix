{
  "activesupport" = {
    version = "4.2.5";
    source = {
      type = "gem";
      sha256 = "1w2znchjbgzj3sgp0581q15rikcj1cji80ki2ky8fwdnjxlh54mb";
    };
    dependencies = [
      "i18n"
      "json"
      "minitest"
      "thread_safe"
      "tzinfo"
    ];
  };
  "amq-protocol" = {
    version = "1.9.2";
    source = {
      type = "gem";
      sha256 = "1gl479j003vixfph5jmdskl20il8816y0flp4msrc8im3b5iiq3r";
    };
  };
  "amqp" = {
    version = "1.5.0";
    source = {
      type = "gem";
      sha256 = "0jlcwyvjz0b28wxdabkyhdqyqp5ji56ckfywsy9mgp0m4wfbrh8c";
    };
    dependencies = [
      "amq-protocol"
      "eventmachine"
    ];
  };
  "async_sinatra" = {
    version = "1.2.0";
    source = {
      type = "gem";
      sha256 = "0sjdvkchq5blvfdahhrlipsx5sr9kfmdx0zxssjlfkz54dbl14m0";
    };
    dependencies = [
      "rack"
      "sinatra"
    ];
  };
  "aws" = {
    version = "2.10.2";
    source = {
      type = "gem";
      sha256 = "0fmlilz3gxml4frf5q0hnvrw9xfr7zhwfmac3f5k63czdf5qdzrc";
    };
    dependencies = [
      "http_connection"
      "uuidtools"
      "xml-simple"
    ];
  };
  "aws-es-transport" = {
    version = "0.1.4";
    source = {
      type = "gem";
      sha256 = "1r2if0jcbw3xx019fs6lqkz65nffwgh7hjbh5fj13hi09g505m3m";
    };
    dependencies = [
      "aws-sdk"
      "elasticsearch"
      "faraday"
      "faraday_middleware"
    ];
  };
  "aws-sdk" = {
    version = "2.6.3";
    source = {
      type = "gem";
      sha256 = "0sy3c7rbf1xczab3hn5f04db7r6gm1l5gp96ajv2l1wmvh440avq";
    };
    dependencies = [
      "aws-sdk-resources"
    ];
  };
  "aws-sdk-core" = {
    version = "2.6.3";
    source = {
      type = "gem";
      sha256 = "0mbkb47nkzdvhnj5x0aqx9gb57snqa1fylb2x3ji5p5y4nv6nn4f";
    };
    dependencies = [
      "jmespath"
    ];
  };
  "aws-sdk-resources" = {
    version = "2.6.3";
    source = {
      type = "gem";
      sha256 = "0f5sm0jcnc6av40z0dvhl8yqh79w59p5m5v75kfqdv3z42ikhmnl";
    };
    dependencies = [
      "aws-sdk-core"
    ];
  };
  "bson" = {
    version = "1.12.3";
    source = {
      type = "gem";
      sha256 = "0r8h83d4wh9yi1r80hz91as6nc2b0yl6xarmfxjrdrzl7mdgcyx6";
    };
  };
  "bson_ext" = {
    version = "1.12.3";
    source = {
      type = "gem";
      sha256 = "1wyfasc304spafd5mm9hv195vinh79yrbdq8yym4s7xry9rbifcy";
    };
    dependencies = [
      "bson"
    ];
  };
  "childprocess" = {
    version = "0.5.8";
    source = {
      type = "gem";
      sha256 = "1lv7axi1fhascm9njxh3lx1rbrnsm8wgvib0g7j26v4h1fcphqg0";
    };
    dependencies = [
      "ffi"
    ];
  };
  "daemons" = {
    version = "1.2.4";
    source = {
      type = "gem";
      sha256 = "1bmb4qrd95b5gl3ym5j3q6mf090209f4vkczggn49n56w6s6zldz";
    };
  };
  "dentaku" = {
    version = "2.0.4";
    source = {
      type = "gem";
      sha256 = "18ga010bbhsgc876vf6z6swfnk2mgj30y96rcd4yafvmwnj5djgz";
    };
  };
  "dnsbl-client" = {
    version = "1.0.2";
    source = {
      type = "gem";
      sha256 = "1357r0y8xfnay05l9h26rrcqrjlnz0hy421g18pfrwm1psf3pp04";
    };
  };
  "dnsruby" = {
    version = "1.58.0";
    source = {
      type = "gem";
      sha256 = "0vf1940vxh3f387b1albb7r90zxrybaiw8094hf5z4zxc97ys7dj";
    };
  };
  "domain_name" = {
    version = "0.5.20160826";
    source = {
      type = "gem";
      sha256 = "0rg7gvp45xmb5qz8ydp7ivw05hhplh6k7mbawrpvkysl2c77w5xx";
    };
    dependencies = [
      "unf"
    ];
  };
  "elasticsearch" = {
    version = "1.0.18";
    source = {
      type = "gem";
      sha256 = "1wdy17i56b4m7akp7yavnr8vhfhyz720waphmixq05dj21b11hl0";
    };
    dependencies = [
      "elasticsearch-api"
      "elasticsearch-transport"
    ];
  };
  "elasticsearch-api" = {
    version = "1.0.18";
    source = {
      type = "gem";
      sha256 = "1v6nb3ajz5rack3p4b4nz37hs0zb9x738h2ms8cc4plp6wqh1w5s";
    };
    dependencies = [
      "multi_json"
    ];
  };
  "elasticsearch-transport" = {
    version = "1.0.18";
    source = {
      type = "gem";
      sha256 = "0smfrz8nq49hgf67y5ayxa9i4rmmi0q4m51l0h499ykq4cvcwv6i";
    };
    dependencies = [
      "faraday"
      "multi_json"
    ];
  };
  "em-redis-unified" = {
    version = "1.0.1";
    source = {
      type = "gem";
      sha256 = "0rzf2c2cbfc1k5jiahmgd3c4l9z5f74b6a549v44n5j1hyj03m9v";
    };
    dependencies = [
      "eventmachine"
    ];
  };
  "em-worker" = {
    version = "0.0.2";
    source = {
      type = "gem";
      sha256 = "0z4jx9z2q5hxvdvik4yp0ahwfk69qsmdnyp72ln22p3qlkq2z5wk";
    };
    dependencies = [
      "eventmachine"
    ];
  };
  "erubis" = {
    version = "2.7.0";
    source = {
      type = "gem";
      sha256 = "1fj827xqjs91yqsydf0zmfyw9p4l2jz5yikg3mppz6d7fi8kyrb3";
    };
  };
  "eventmachine" = {
    version = "1.0.9.1";
    source = {
      type = "gem";
      sha256 = "17jr1caa3ggg696dd02g2zqzdjqj9x9q2nl7va82l36f7c5v6k4z";
    };
  };
  "faraday" = {
    version = "0.9.2";
    source = {
      type = "gem";
      sha256 = "1kplqkpn2s2yl3lxdf6h7sfldqvkbkpxwwxhyk7mdhjplb5faqh6";
    };
    dependencies = [
      "multipart-post"
    ];
  };
  "faraday_middleware" = {
    version = "0.10.0";
    source = {
      type = "gem";
      sha256 = "0nxia26xzy8i56qfyz1bg8dg9yb26swpgci8n5jry8mh4bnx5r5h";
    };
    dependencies = [
      "faraday"
    ];
  };
  "ffi" = {
    version = "1.9.14";
    source = {
      type = "gem";
      sha256 = "1nkcrmxqr0vb1y4rwliclwlj2ajsi4ddpdx2gvzjy0xbkk5iqzfp";
    };
  };
  "fileutils" = {
    version = "0.7";
    source = {
      type = "gem";
      sha256 = "046m22flkcwpfzm2g60mh3wax114z8l4hhp4sh4sn1ci7zm9xayz";
    };
    dependencies = [
      "rmagick"
    ];
  };
  "http-cookie" = {
    version = "1.0.2";
    source = {
      type = "gem";
      sha256 = "0cz2fdkngs3jc5w32a6xcl511hy03a7zdiy988jk1sf3bf5v3hdw";
    };
    dependencies = [
      "domain_name"
    ];
  };
  "http_connection" = {
    version = "1.4.4";
    source = {
      type = "gem";
      sha256 = "0gj3imp4yyys5x2awym1nwy5qandmmpsjpf66m76d0gxfd4zznk9";
    };
  };
  "i18n" = {
    version = "0.7.0";
    source = {
      type = "gem";
      sha256 = "1i5z1ykl8zhszsxcs8mzl8d0dxgs3ylz8qlzrw74jb0gplkx6758";
    };
  };
  "inifile" = {
    version = "3.0.0";
    source = {
      type = "gem";
      sha256 = "1c5zmk7ia63yw5l2k14qhfdydxwi1sah1ppjdiicr4zcalvfn0xi";
    };
  };
  "jmespath" = {
    version = "1.3.1";
    source = {
      type = "gem";
      sha256 = "07w8ipjg59qavijq59hl82zs74jf3jsp7vxl9q3a2d0wpv5akz3y";
    };
  };
  "json" = {
    version = "1.8.3";
    source = {
      type = "gem";
      sha256 = "1nsby6ry8l9xg3yw4adlhk2pnc7i0h0rznvcss4vk3v74qg0k8lc";
    };
  };
  "libxml-ruby" = {
    version = "2.9.0";
    source = {
      type = "gem";
      sha256 = "1prdc73db1p7zkdsp41523qmmn95981kmsf91kn7c8yam9w64np2";
    };
  };
  "libxml-xmlrpc" = {
    version = "0.1.5";
    source = {
      type = "gem";
      sha256 = "0xqp6j529aa2ygp8xrlz9a0pnh64x458jr4pywqanfw7i64a3qdb";
    };
    dependencies = [
      "libxml-ruby"
    ];
  };
  "mail" = {
    version = "2.6.3";
    source = {
      type = "gem";
      sha256 = "1nbg60h3cpnys45h7zydxwrl200p7ksvmrbxnwwbpaaf9vnf3znp";
    };
    dependencies = [
      "mime-types"
    ];
  };
  "mailgun-ruby" = {
    version = "1.0.3";
    source = {
      type = "gem";
      sha256 = "1aqa0ispfn27g20s8s517cykghycxps0bydqargx7687w6d320yb";
    };
    dependencies = [
      "json"
      "rest-client"
    ];
  };
  "mime-types" = {
    version = "2.99.3";
    source = {
      type = "gem";
      sha256 = "03j98xr0qw2p2jkclpmk7pm29yvmmh0073d8d43ajmr0h3w7i5l9";
    };
  };
  "minitest" = {
    version = "5.9.1";
    source = {
      type = "gem";
      sha256 = "0300naf4ilpd9sf0k8si9h9sclkizaschn8bpnri5fqmvm9ybdbq";
    };
  };
  "mixlib-cli" = {
    version = "1.7.0";
    source = {
      type = "gem";
      sha256 = "0647msh7kp7lzyf6m72g6snpirvhimjm22qb8xgv9pdhbcrmcccp";
    };
  };
  "mongo" = {
    version = "1.12.3";
    source = {
      type = "gem";
      sha256 = "0y0axsmd8x7f1417hd257r6bb4k4n3rgb5188bqcsyp082jgp85j";
    };
    dependencies = [
      "bson"
    ];
  };
  "multi_json" = {
    version = "1.11.2";
    source = {
      type = "gem";
      sha256 = "1rf3l4j3i11lybqzgq2jhszq7fh7gpmafjzd14ymp9cjfxqg596r";
    };
  };
  "multipart-post" = {
    version = "2.0.0";
    source = {
      type = "gem";
      sha256 = "09k0b3cybqilk1gwrwwain95rdypixb2q9w65gd44gfzsd84xi1x";
    };
  };
  "mysql" = {
    version = "2.9.1";
    source = {
      type = "gem";
      sha256 = "1y2b5rnspa0lllvqd6694hbkjhdn45389nrm3xfx6xxx6gf35p36";
    };
  };
  "mysql2" = {
    version = "0.3.18";
    source = {
      type = "gem";
      sha256 = "0dap507ba8pj3hpc3y8ammsq51xqflb54p5g262m1z55y6m7fm6k";
    };
  };
  "net-ping" = {
    version = "1.7.8";
    source = {
      type = "gem";
      sha256 = "19p3d39109xvbr4dcjs3g3zliazhc1k3iiw69mgb1w204hc7wkih";
    };
  };
  "netrc" = {
    version = "0.11.0";
    source = {
      type = "gem";
      sha256 = "0gzfmcywp1da8nzfqsql2zqi648mfnx6qwkig3cv36n9m0yy676y";
    };
  };
  "pg" = {
    version = "0.18.3";
    source = {
      type = "gem";
      sha256 = "00g33hdixgync6gp4mn0g0kjz5qygshi47xw58kdpd9n5lzdpg8c";
    };
  };
  "rack" = {
    version = "1.6.4";
    source = {
      type = "gem";
      sha256 = "09bs295yq6csjnkzj7ncj50i6chfxrhmzg1pk6p0vd2lb9ac8pj5";
    };
  };
  "rack-protection" = {
    version = "1.5.3";
    source = {
      type = "gem";
      sha256 = "0cvb21zz7p9wy23wdav63z5qzfn4nialik22yqp6gihkgfqqrh5r";
    };
    dependencies = [
      "rack"
    ];
  };
  "redis" = {
    version = "3.2.1";
    source = {
      type = "gem";
      sha256 = "16jzlqp80qiqg5cdc9l144n6k3c5qj9if4pgij87sscn8ahi993k";
    };
  };
  "rest-client" = {
    version = "1.8.0";
    source = {
      type = "gem";
      sha256 = "1m8z0c4yf6w47iqz6j2p7x1ip4qnnzvhdph9d5fgx081cvjly3p7";
    };
    dependencies = [
      "http-cookie"
      "mime-types"
      "netrc"
    ];
  };
  "rmagick" = {
    version = "2.16.0";
    source = {
      type = "gem";
      sha256 = "0m9x15cdlkcb9826s3s2jd97hxf50hln22p94x8hcccxi1lwklq6";
    };
  };
  "ruby-dbus" = {
    version = "0.11.0";
    source = {
      type = "gem";
      sha256 = "1ga8q959i8j8iljnw9hgxnjlqz1q0f95p9r3hyx6r5fl657qbx8z";
    };
  };
  "ruby-supervisor" = {
    version = "0.0.2";
    source = {
      type = "gem";
      sha256 = "07g0030sb9psrnz3b8axyjrcgwrmd38p0m05nq24bvrlvav4vkc0";
    };
  };
  "sensu" = {
    version = "0.22.1";
    source = {
      type = "gem";
      sha256 = "0vyk8m4acjzn4i2q41gabpmrlqcl2x4ivf58m0hqn3x7l45ma605";
    };
    dependencies = [
      "async_sinatra"
      "em-redis-unified"
      "eventmachine"
      "multi_json"
      "sensu-extension"
      "sensu-extensions"
      "sensu-logger"
      "sensu-settings"
      "sensu-spawn"
      "sensu-transport"
      "sinatra"
      "thin"
      "uuidtools"
    ];
  };
  "sensu-extension" = {
    version = "1.3.0";
    source = {
      type = "gem";
      sha256 = "1ms7g76vng0dzaq86g4s8mdszjribm6v6vkbmh4psf988xw95a2b";
    };
    dependencies = [
      "eventmachine"
    ];
  };
  "sensu-extensions" = {
    version = "1.4.0";
    source = {
      type = "gem";
      sha256 = "16npdf1hcpcn47wmznkwcikynxzb2jv2irqlvprjlapy2m6m4c62";
    };
    dependencies = [
      "multi_json"
      "sensu-extension"
      "sensu-logger"
      "sensu-settings"
    ];
  };
  "sensu-logger" = {
    version = "1.1.0";
    source = {
      type = "gem";
      sha256 = "1pbzbr83df4awndr49f1z7z1bl9n73nkf1xcnlkjcnpnb3yy07pw";
    };
    dependencies = [
      "eventmachine"
      "multi_json"
    ];
  };
  "sensu-plugin" = {
    version = "1.2.0";
    source = {
      type = "gem";
      sha256 = "1k8mkkwb70z2j5lq457y7lsh5hr8gzd53sjbavpqpfgy6g4bxrg8";
    };
    dependencies = [
      "json"
      "mixlib-cli"
    ];
  };
  "sensu-plugins-disk-checks" = {
    version = "1.1.3";
    source = {
      type = "gem";
      sha256 = "0d2qcn2ffirvnrnpw98kll412jy7plhg5x2kkpky79a8nx8bbnp5";
    };
    dependencies = [
      "sensu-plugin"
      "sys-filesystem"
    ];
  };
  "sensu-plugins-dns" = {
    version = "0.0.6";
    source = {
      type = "gem";
      sha256 = "0267cr8lxim2cypqn3dbjz8r5kzbzadbkssx790z1ssncjgl8qa9";
    };
    dependencies = [
      "dnsruby"
      "sensu-plugin"
    ];
  };
  "sensu-plugins-elasticsearch" = {
    version = "1.0.0";
    source = {
      type = "gem";
      sha256 = "1s8cd5k222pkvbfbh8z0r9k19zjgsimns9s9pnpm8zf2ckd9syr6";
    };
    dependencies = [
      "aws-es-transport"
      "elasticsearch"
      "json"
      "rest-client"
      "sensu-plugin"
    ];
  };
  "sensu-plugins-entropy-checks" = {
    version = "0.0.3";
    source = {
      type = "gem";
      sha256 = "1sk9hkwzhx8vy0jy4gq9igadixbjzw3fvskskl29xcs92cqk1j32";
    };
    dependencies = [
      "sensu-plugin"
    ];
  };
  "sensu-plugins-logs" = {
    version = "0.0.3";
    source = {
      type = "gem";
      sha256 = "17vk6c3nr3f5cjdwdcm5a6547s5xy32w5kkdzzy2zvafwxgb6dh9";
    };
    dependencies = [
      "fileutils"
      "sensu-plugin"
    ];
  };
  "sensu-plugins-mailer" = {
    version = "0.1.2";
    source = {
      type = "gem";
      sha256 = "0ysqwssa5jfn1wgsn9pmqiy85swkmk87xki4i7q3w260rl138bf9";
    };
    dependencies = [
      "aws"
      "erubis"
      "mail"
      "mailgun-ruby"
      "sensu-plugin"
    ];
  };
  "sensu-plugins-mongodb" = {
    version = "0.0.8";
    source = {
      type = "gem";
      sha256 = "120ay9kclypqf3rx4xv2cgay0hi8hvql0xzlfpyamxvbgqdfn532";
    };
    dependencies = [
      "bson"
      "bson_ext"
      "mongo"
      "sensu-plugin"
    ];
  };
  "sensu-plugins-mysql" = {
    version = "0.0.4";
    source = {
      type = "gem";
      sha256 = "0j4bqm4wi8i86cbpbmrp88q71bzcmsfaf4icb2ml4w2db0ccr2d9";
    };
    dependencies = [
      "aws"
      "inifile"
      "mysql"
      "mysql2"
      "sensu-plugin"
    ];
  };
  "sensu-plugins-network-checks" = {
    version = "0.1.4";
    source = {
      type = "gem";
      sha256 = "1n474lg1fdjd9908dfwdhs1d18rj2g11fqf1sp761addg3rlh0wx";
    };
    dependencies = [
      "activesupport"
      "dnsbl-client"
      "net-ping"
      "sensu-plugin"
      "whois"
    ];
  };
  "sensu-plugins-postgres" = {
    version = "0.0.7";
    source = {
      type = "gem";
      sha256 = "1xh2gzpacmzrzxj7ibczdrzgf3hdja0yl5cskfqypiq007d48gr9";
    };
    dependencies = [
      "dentaku"
      "pg"
      "sensu-plugin"
    ];
  };
  "sensu-plugins-redis" = {
    version = "0.1.0";
    source = {
      type = "gem";
      sha256 = "0v3gasiz3hgp6r4yzhalpqk2g4kcqqism01c3apyzcn0f6pvp3z7";
    };
    dependencies = [
      "redis"
      "sensu-plugin"
    ];
  };
  "sensu-plugins-ssl" = {
    version = "0.0.6";
    source = {
      type = "gem";
      sha256 = "15md1czbvpw1d63x91k1x4rwhsgd88shmx0pv8083bywl2c87yqq";
    };
    dependencies = [
      "rest-client"
      "sensu-plugin"
    ];
  };
  "sensu-plugins-supervisor" = {
    version = "0.0.3";
    source = {
      type = "gem";
      sha256 = "1idds9x01ccxldzi00xz5nx3jizdn3ywm1ijwmw2yb6zb171k0zi";
    };
    dependencies = [
      "libxml-xmlrpc"
      "ruby-supervisor"
      "sensu-plugin"
    ];
  };
  "sensu-plugins-systemd" = {
    version = "0.0.1";
    source = {
      type = "git";
      url = "https://github.com/nyxcharon/sensu-plugins-systemd.git";
      rev = "be972959c5f6cdc989b1122db72a4b10a1ecce77";
      sha256 = "123fnj9yiwbzxax9c14zy5iwc3qaldn5nqibs9k0nysr9zwkygpa";
      fetchSubmodules = false;
    };
    dependencies = [
      "sensu-plugin"
      "systemd-bindings"
    ];
  };
  "sensu-settings" = {
    version = "3.3.0";
    source = {
      type = "gem";
      sha256 = "0fk5chvzv946yg6cqpjlpjw5alwimg8rsxs3knhbgdanyrbh6m32";
    };
    dependencies = [
      "multi_json"
    ];
  };
  "sensu-spawn" = {
    version = "1.7.0";
    source = {
      type = "gem";
      sha256 = "06krhrgdb1b83js185ljh32sd30r8irfb1rjs0wl2amn6w5nrdi6";
    };
    dependencies = [
      "childprocess"
      "em-worker"
      "eventmachine"
    ];
  };
  "sensu-transport" = {
    version = "4.0.0";
    source = {
      type = "gem";
      sha256 = "153r2wgqh2bxrgml2ag7iyw7w5r4jmcbqj96lcq5gr98761zzb8l";
    };
    dependencies = [
      "amq-protocol"
      "amqp"
      "em-redis-unified"
      "eventmachine"
    ];
  };
  "sinatra" = {
    version = "1.4.6";
    source = {
      type = "gem";
      sha256 = "1hhmwqc81ram7lfwwziv0z70jh92sj1m7h7s9fr0cn2xq8mmn8l7";
    };
    dependencies = [
      "rack"
      "rack-protection"
      "tilt"
    ];
  };
  "sys-filesystem" = {
    version = "1.1.5";
    source = {
      type = "gem";
      sha256 = "08zi702aq7cgm3wmmai2f18ph30yvincnlk1crza8axrjvf7fr25";
    };
    dependencies = [
      "ffi"
    ];
  };
  "systemd-bindings" = {
    version = "0.0.1.1";
    source = {
      type = "gem";
      sha256 = "1bprj8njmzbshjmrabra3djhw6737hn9mm0n8sxb7wv1znpr7lds";
    };
    dependencies = [
      "ruby-dbus"
    ];
  };
  "thin" = {
    version = "1.6.3";
    source = {
      type = "gem";
      sha256 = "1m56aygh5rh8ncp3s2gnn8ghn5ibkk0bg6s3clmh1vzaasw2lj4i";
    };
    dependencies = [
      "daemons"
      "eventmachine"
      "rack"
    ];
  };
  "thread_safe" = {
    version = "0.3.5";
    source = {
      type = "gem";
      sha256 = "1hq46wqsyylx5afkp6jmcihdpv4ynzzq9ygb6z2pb1cbz5js0gcr";
    };
  };
  "tilt" = {
    version = "2.0.5";
    source = {
      type = "gem";
      sha256 = "0lgk8bfx24959yq1cn55php3321wddw947mgj07bxfnwyipy9hqf";
    };
  };
  "tzinfo" = {
    version = "1.2.2";
    source = {
      type = "gem";
      sha256 = "1c01p3kg6xvy1cgjnzdfq45fggbwish8krd0h864jvbpybyx7cgx";
    };
    dependencies = [
      "thread_safe"
    ];
  };
  "unf" = {
    version = "0.1.4";
    source = {
      type = "gem";
      sha256 = "0bh2cf73i2ffh4fcpdn9ir4mhq8zi50ik0zqa1braahzadx536a9";
    };
    dependencies = [
      "unf_ext"
    ];
  };
  "unf_ext" = {
    version = "0.0.7.2";
    source = {
      type = "gem";
      sha256 = "04d13bp6lyg695x94whjwsmzc2ms72d94vx861nx1y40k3817yp8";
    };
  };
  "uuidtools" = {
    version = "2.1.5";
    source = {
      type = "gem";
      sha256 = "0zjvq1jrrnzj69ylmz1xcr30skf9ymmvjmdwbvscncd7zkr8av5g";
    };
  };
  "whois" = {
    version = "3.6.3";
    source = {
      type = "gem";
      sha256 = "1ckr4w1gba1m1yabl2piy7y9wy3hc0gzdxnqkr74ffk5xqbn0k49";
    };
    dependencies = [
      "activesupport"
    ];
  };
  "xml-simple" = {
    version = "1.1.5";
    source = {
      type = "gem";
      sha256 = "0xlqplda3fix5pcykzsyzwgnbamb3qrqkgbrhhfz2a2fxhrkvhw8";
    };
  };
}