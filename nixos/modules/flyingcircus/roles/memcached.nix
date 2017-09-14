{ config, lib, pkgs, ... }: with lib;

let
  cfg = config.flyingcircus.roles.memcached;
  fclib = import ../lib;

  srv = fclib.listenAddresses config "ethsrv";

  defaultConfig = ''
    {
      "port": 11211,
      "maxMemory": 64,
      "maxConnections": 1024
    }
  '';

  localConfig =
    fclib.jsonFromFile "/etc/local/memcached/memcached.json" defaultConfig;

  addr = head srv;
  port = localConfig.port;

in
{
  options = {
    flyingcircus.roles.memcached = {

      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable the Flying Circus memcached role.";
      };

    };
  };

  config = mkMerge [

  (mkIf cfg.enable {

    system.activationScripts.fcio-memcached = ''
      install -d -o ${toString config.ids.uids.memcached} -g service -m 02775 \
        /etc/local/memcached
    '';

    environment.etc = {
      "local/memcached/README.txt".text = ''
        Put your local memcached configuration as JSON into `memcached.json`.

        Example:
        ${defaultConfig}
      '';
      "local/memcached/memcached.json.example".text = defaultConfig;
    };

    services.memcached = {
      enable = true;
      listen = concatStringsSep "," srv;
    } // localConfig;

    flyingcircus.services.sensu-client.checks.memcached = {
        notification = "memcached alive";
        command = "check-memcached-stats.rb -h ${addr} -p ${toString port}";
      };

      services.telegraf.inputs = {
        memcached = [{
          servers = ["${addr}:${toString port}"];
        }];
      };
  })

  {
    flyingcircus.roles.statshost.prometeusMetricRelabel = [
      { source_labels = ["__name__"];
       regex = "(memcached)_(.+)_hits";
       replacement = "\${2}";
       target_label = "command";
      }
      { source_labels = ["__name__"];
       regex = "(memcached)_(.+)_hits";
       replacement = "hit";
       target_label = "status";
      }
      { source_labels = ["__name__"];
       regex = "(memcached)_(.+)_hits";
       replacement = "memcached_commands_total";
       target_label = "__name__";
      }

      { source_labels = ["__name__"];
       regex = "(memcached)_(.+)_misses";
       replacement = "\${2}";
       target_label = "command";
      }
      { source_labels = ["__name__"];
       regex = "(memcached)_(.+)_misses";
       replacement = "miss";
       target_label = "status";
      }
      { source_labels = ["__name__"];
       regex = "(memcached)_(.+)_misses";
       replacement = "memcached_commands_total";
       target_label = "__name__";
      }
    ];
  }
  ];
}
