{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.services.termix-server;
  defaultUser = "termix";
in
{
  options.services.termix-server = {
    enable = mkEnableOption "the Termix server";

    package = mkPackageOption pkgs [ "termix-server" ] { };

    openFirewall = mkOption {
      type = types.bool;
      default = false;
      description = "Open ports in the firewall for the server.";
    };

    # Note: Termix actually uses multiple hardcoded ports (30001-30007), so this option is not used
    # port = mkOption {
    #   type = types.port;
    #   default = 8080;
    #   description = "Listening port.";
    # };

    dataDir = mkOption {
      type = types.path;
      default = "/var/lib/termix";
      description = ''
        The directory to store all user data, such as the database and configuration files. If left
        as the default value this directory will automatically be created before the Termix service starts,
        otherwise the sysadmin is responsible for ensuring the directory exists with appropriate ownership
        and permissions.
      '';
    };

    user = mkOption {
      type = types.str;
      default = defaultUser;
      description = ''
        User under which Termix runs. If left as the default value this user
        will automatically be created on system activation, otherwise the
        sysadmin is responsible for ensuring the user exists.
      '';
    };

    group = mkOption {
      type = types.str;
      default = defaultUser;
      description = ''
        Group under which Termix runs. If left as the default value this group
        will automatically be created on system activation, otherwise the
        sysadmin is responsible for ensuring the group exists.
      '';
    };
  };

  config = mkIf cfg.enable {
    networking.firewall = mkIf cfg.openFirewall {
      allowedTCPPorts = [
        30001
        30002
        30003
        30004
        30005
        30006
        30007
      ];
    };

    # Create user/group only if custom values are specified
    users.users = mkIf (cfg.user != defaultUser) {
      "${cfg.user}" = {
        isSystemUser = true;
        group = cfg.group;
      };
    };

    users.groups = mkIf (cfg.group != defaultUser) {
      "${cfg.group}" = { };
    };

    systemd.services.termix-server = {
      description = "Termix Server";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      environment = {
        DATA_DIR = if cfg.user == defaultUser then "%S/termix" else cfg.dataDir;
        PORT = toString cfg.port;
        NODE_ENV = "production";
      };
      serviceConfig = mkMerge [
        {
          User = cfg.user;
          Group = cfg.group;
          ExecStart = "${cfg.package}/bin/termix";
          PrivateTmp = true;
          Restart = "always";
          WorkingDirectory = if cfg.user == defaultUser then "%S/termix" else cfg.dataDir;
        }
        (mkIf (cfg.user == defaultUser) {
          DynamicUser = true;
          StateDirectory = "termix";
        })
        (mkIf (cfg.dataDir == "/var/lib/termix" && cfg.user != defaultUser) {
          StateDirectory = "termix";
        })
      ];
    };
  };
}
