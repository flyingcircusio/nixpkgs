{ config, lib, pkgs, ... }: with lib;

let
  cfg = config.flyingcircus.roles.elasticsearch;
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

  defaultClusterName =
    lib.attrByPath ["parameters" "resource_group"] "elasticsearch" config.flyingcircus.enc;

  clusterName =
    if cfg.clusterName == null
    then (fclib.configFromFile /etc/local/elasticsearch/clusterName defaultClusterName)
    else cfg.clusterName;

  currentMemory = fclib.current_memory config 1024;
  esHeap =
    fclib.min [
      (currentMemory / cfg.heapDivisor)
      (31 * 1024)];

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
        type = types.listOf types.string;
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
      serviceConfig.LimitNOFILE = 65536;
      serviceConfig.LimitMEMLOCK = "infinity";
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
      Clustering:
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
