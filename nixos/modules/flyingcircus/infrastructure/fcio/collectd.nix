{ config, pkgs, lib, ... }:

with lib;

let
  enc = config.flyingcircus.enc;
  params = if enc ? parameters then enc.parameters else {};

in
mkIf (params ? location && params ? resource_group) {
  services.collectd.enable = true;
  services.collectd.extraConfig = ''
    Interval 5

    LoadPlugin cpu
    LoadPlugin disk
    LoadPlugin entropy
    LoadPlugin interface
    LoadPlugin load
    LoadPlugin memory
    LoadPlugin processes
    LoadPlugin swap
    LoadPlugin syslog
    LoadPlugin uptime
    LoadPlugin vmem
    LoadPlugin write_graphite

    <Plugin "syslog">
        LogLevel info
    </Plugin>

    <Plugin "disk">
      Disk "/^[sv]d[a-z]$|^vg.*-./"
    </Plugin>

    <Plugin "write_graphite">
     <Node "stats.flyingcircus.io">
       Host "stats.flyingcircus.io"
       Port "2003"
       Prefix "fcio.${params.location}.${params.resource_group}.virtual.generic."
       Protocol "udp"
       EscapeCharacter "_"
       SeparateInstances true
     </Node>
    </Plugin>
  '' +
  concatMapStringsSep "\n"
    (ifname: ''
      <Plugin "interface">
        Interface "${ifname}"
      </Plugin>
     '')
     (attrNames config.networking.interfaces);
}
