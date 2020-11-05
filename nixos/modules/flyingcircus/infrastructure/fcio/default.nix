{ config, lib, pkgs, ... }:
# Configuration for running on Flying Circus owned and operated infrastructure
# (i.e. not on Vagrant but in DEV, RZOB, ...)

with lib;

let
  cfg = config.flyingcircus;

in
{
  imports = [
      <nixpkgs/nixos/modules/profiles/qemu-guest.nix>
      ./quota.nix
      ./telegraf.nix
  ];

  environment.systemPackages = with pkgs; [
    fcmaintenance
  ];

  systemd.services.qemu-guest-agent = {
    description = "The Qemu guest agent.";
    wantedBy = [ "basic.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.qemu}/bin/qemu-ga -m virtio-serial -p /dev/virtio-ports/org.qemu.guest_agent.0";
      Restart = "always";
      RestartSec = "5s";
    };
  };

  # XXX This is rather sad, but Qemu can't ignore the mount and then we can't
  # freeze the filesystem properly. :(
  # Would need qemu to help here and notice that this is the same device as
  # the root.
  nix.readOnlyStore = false;
  nix.extraOptions = ''
    http-connections = 1
  '';

  system.activationScripts.readOnlyStore =
    if config.nix.readOnlyStore then ''
      ${pkgs.utillinux}/bin/mount | grep "/nix/store" > /dev/null ||
        echo "Want to activate nix.readOnlyStore=true" > /reboot
    '' else ''
      ${pkgs.utillinux}/bin/mount | grep "/nix/store" > /dev/null &&
        echo "Want to activate nix.readOnlyStore=false" > /reboot || true
    '';


   # The upstream ubuntu.conf disables _all_ watchdogs. That's insane.
  boot.kernelModules = [ "i6300esb" ];
  environment.etc."modprobe.d/ubuntu.conf".source = lib.mkForce ./modprobe.conf;

  boot.blacklistedKernelModules = [ "bochs_drm" ];
  boot.initrd.supportedFilesystems = [ "xfs" ];
  boot.kernelParams = [
    # Crash management
    "panic=1"
    "boot.panic_on_fail" # panic_on_fail is a NixOSism managed by stage-1-init.sh

    # Output management
    "console=ttyS0"
    "systemd.journald.forward_to_console=no"
    "systemd.log_target=kmsg"
    "nosetmode"
    ];

  boot.consoleLogLevel = 7;

  # installs /dev/disk/device-by-alias/*
  services.udev.extraRules = ''
    # Select GRUB boot device
    SUBSYSTEM=="block", KERNEL=="[vs]da", SYMLINK+="disk/device-by-alias/root"
  '';

  # Changing this can be nasty: grub is reconfigured before any configuration
  # is activated. This means we currently have to make sure that device exists
  # when switching the configuration to it.
  # https://github.com/NixOS/nixpkgs/issues/12833
  boot.loader.grub.device = "/dev/disk/device-by-alias/root";
  boot.loader.grub.fsIdentifier = "provided";
  boot.loader.grub.splashImage = null;
  boot.loader.grub.gfxmodeBios = "text";
  boot.loader.grub.timeout = 3;
  boot.loader.grub.version = 2;
  boot.supportedFilesystems = [ "xfs" ];
  boot.vesa = false;

  boot.kernel.sysctl."vm.swappiness" = mkDefault 10;

  networking.hostName = if config.flyingcircus.enc ? name
    then config.flyingcircus.enc.name
    else "default";

  networking.domain = "gocept.net";

  services.openssh.permitRootLogin = "without-password";

  fileSystems."/".device = "/dev/disk/by-label/root";
  fileSystems."/tmp".device = "/dev/disk/by-label/tmp";
  swapDevices = [ { device = "/dev/disk/by-label/swap"; } ];

  users.users.root = {
    initialHashedPassword = "*";
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA/lhMiMJBednrahZUJvb+dZVhLysbcuGf4p2J4D6MU/ ctheune@fourteen-3.local"
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDSejGFORJ7hlFraV3caVir3rWlo/QcsWptWrukk2C7eaGu/8tXMKgPtBHYdk4DYRi7EcPROllnFVzyVTLS/2buzfIy7XDjn7bwHzlHoBHZ4TbC9auqW3j5oxTDA4s2byP6b46Dh93aEP9griFideU/J00jWeHb27yIWv+3VdstkWTiJwxubspNdDlbcPNHBGOE+HNiAnRWzwyj8D0X5y73MISC3pSSYnXJWz+fI8IRh5LSLYX6oybwGX3Wu+tlrQjyN1i0ONPLxo5/YDrS6IQygR21j+TgLXaX8q8msi04QYdvnOqk1ntbY4fU8411iqoSJgCIG18tOgWTTOcBGcZX directory@directory.fcio.net"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB6MKl9D9mzhuB6/sQXNCEW5qq4R7mXlpnxi+QZSGi57 root/ckauhaus@fcio.net"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKqKaOCYLUxtjAs9e3amnTRH5NM2j0kjLOE+5ZGy9/W4 zagy@drrr.local"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAg5mbkbBk0dngSVmlZJEH0hAUqnu3maJzqEV9Su1Cff flanitz"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKIlrvXV9TzM1uppd8oAbph1dcab6h28VZSUthsp2eZL christians@colbert"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOpJ59uGzQAB/n9YFQoOPWHiUFaKPGj2OivAxQmTkeyN ts"
    ];
  };

  systemd.targets.basic.unitConfig.JobTimeoutAction = "none";

  systemd.ctrl-alt-del = "poweroff.target";
  systemd.extraConfig = ''
    RuntimeWatchdogSec=60
  '';

  systemd.timers.serial-console-liveness = {
    description = "Timer for Serial console liveness marker";
    requiredBy = [ "serial-getty@ttyS0.service" ];
    timerConfig = {
      Unit = "serial-console-liveness.service";
      OnBootSec = "10m";
      OnUnitActiveSec = "10m";
    };
  };

  systemd.services.serial-console-liveness = {
    description = "Serial console liveness marker";
    serviceConfig.Type = "oneshot";
    script = "echo \"$(date) -- SERIAL CONSOLE IS LIVE --\" > /dev/ttyS0";
  };

  # Configure time keeping
  services.ntp.enable = false;
  services.chrony.enable = true;
  services.chrony.servers =
    if (hasAttrByPath [ "parameters" "location" ] cfg.enc)
    then cfg.static.ntpservers.${cfg.enc.parameters.location}
    else [];
}
