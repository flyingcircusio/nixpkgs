{ config, lib, pkgs, ... }: with lib;

let
  cfg = config.flyingcircus.roles.elasticsearch;
  cfg_service = config.services.elasticsearch;
  fclib = import ../lib;

  esNodes =
    if cfg.esNodes == null
    then map
      (service: service.address)
      (filter
        (s: s.service == "elasticsearch-node")
        config.flyingcircus.enc_services)
    else cfg.esNodes;
  thisNode = "${config.networking.hostName}.${config.networking.domain}";

  defaultClusterName = config.networking.hostName;

  clusterName =
    if cfg.clusterName == null
    then (fclib.configFromFile /etc/local/elasticsearch/clusterName defaultClusterName)
    else cfg.clusterName;

  currentMemory = fclib.current_memory config 1024;

  esHeap =
    fclib.min [
      (currentMemory / cfg.heapDivisor)
      (31 * 1024)];

  configDir = pkgs.buildEnv {
      name = "elasticsearch-config";
      paths = [
        (pkgs.writeTextDir "elasticsearch.yml" esConfig)
        (pkgs.writeTextDir "logging.yml" cfg_service.logging)
      ];
    };

  esPlugins = pkgs.buildEnv {
        name = "elasticsearch-plugins";
        paths = cfg_service.plugins;
      };

  esConfig = ''
    network.host: ${cfg_service.host}
    network.port: ${toString cfg_service.port}
    network.tcp.port: ${toString cfg_service.tcp_port}
    cluster.name: ${cfg_service.cluster_name}
    ${cfg_service.extraConf}
  '';

in
{

  options = {
    flyingcircus.roles.elasticsearch = {

      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable the Flying Circus elasticsearch role.";
      };

      clusterName = mkOption {
        type = types.nullOr types.string;
        default = null;
        description = ''
          The clusterName elasticsearch will use.
        '';
      };

      dataDir = mkOption {
        type = types.path;
        default = "/srv/elasticsearch";
        description = ''
          Data directory for elasticsearch.
        '';
      };

      heapDivisor = mkOption {
        type = types.int;
        default = 2;
        description = ''
          Tweak amount of memory to use for ES heap
          (systemMemory / heapDivisor)
        '';
      };

      esNodes = mkOption {
        type = types.nullOr (types.listOf types.string);
        default = null;
      };
    };
  };

  config = mkIf cfg.enable {

    services.elasticsearch = {
      enable = true;
      host = thisNode;
      dataDir = cfg.dataDir;
      cluster_name = clusterName;
      plugins = pkgs.elasticsearchPackages;
      extraConf = ''
        node.name: ${config.networking.hostName}
        discovery.zen.ping.unicast.hosts: ${builtins.toJSON esNodes}
        bootstrap.memory_lock: true
      '';
    };
    systemd.services.elasticsearch = {
      environment = {
        ES_HEAP_SIZE = "${toString esHeap}m";
      };
      serviceConfig = fclib.mkPlatform {
        ExecStart = "${pkgs.elasticsearch}/bin/elasticsearch -Des.path.conf=${cfg_service.dataDir}/config -Des.path.scripts=${cfg_service.dataDir}/scripts ${toString cfg_service.extraCmdLineOptions}"; User = "elasticsearch";
        PermissionsStartOnly = true;
        LimitNOFILE = 65536;
        LimitMEMLOCK = "infinity";
      };
      preStart = fclib.mkPlatform ''
        mkdir -m 0700 -p ${cfg_service.dataDir}
        if [ "$(id -u)" = 0 ]; then chown -R elasticsearch ${cfg_service.dataDir}; fi

        # Install plugins
        rm -rf ${cfg_service.dataDir}/plugins || true
        ln -s ${esPlugins} ${cfg_service.dataDir}/plugins

        # Install scripts
        mkdir -p ${cfg_service.dataDir}/scripts

        # Install config
        rm -rf ${cfg_service.dataDir}/config || true
        mkdir -p ${cfg_service.dataDir}/config
        cp -L ${configDir}/* ${cfg_service.dataDir}/config/
      '';
      postStart = mkBefore ''
        until ${pkgs.curl}/bin/curl -s -o /dev/null ${cfg_service.host}:${toString cfg_service.port}; do
          sleep 1
        done
      '';
    };

    # System tweaks
    boot.kernel.sysctl = {
      "vm.max_map_count" = "262144";
    };

    system.activationScripts.fcio-elasticsearch = ''
      install -d -o ${toString config.ids.uids.elasticsearch} -g service -m 02775 \
        /etc/local/elasticsearch/
    '';

    environment.etc."local/elasticsearch/README.txt".text = ''
      Elasticsearch is running on this VM.

      It is forming the cluster "${clusterName}". To change the cluster name,
      add a file named "clusterName" here, with the cluster name as its sole
      contents.
    '';

    flyingcircus.services.sensu-client.checks = {

      es_circuit_breakers = {
        notification = "ES: Circuit Breakers active";
        command = "check-es-circuit-breakers.rb -h ${thisNode}";
      };

      es_cluster_health = {
        notification = "ES: Cluster Health";
        command = "check-es-cluster-health.rb -h ${thisNode}";
      };

      es_file_descriptor = {
        notification = "ES: File descriptors in use";
        command = "check-es-file-descriptors.rb -h ${thisNode}";
      };

      es_heap = {
        notification = "ES: Heap too full";
        command = "check-es-heap.rb -h ${thisNode} -w 75 -c 90 -P";
      };

      es_node_status = {
        notification = "ES: Node status";
        command = "check-es-node-status.rb -h ${thisNode}";
      };

      es_shard_allocation_status = {
        notification = "ES: Shard allocation status";
        command = "check-es-shard-allocation-status.rb -s ${thisNode}";
      };

    };

  };

}
