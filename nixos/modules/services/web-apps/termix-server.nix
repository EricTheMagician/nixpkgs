{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.termix-server;
  defaultUser = "termix";
in {
  options.services.termix-server = {
    enable = mkEnableOption "the Termix server";

    package = mkPackageOption pkgs [ "termix-server" ] { };

    openFirewall = mkOption {
      type = types.bool;
      default = false;
      description = "Open ports in the firewall for the server.";
    };

    port = mkOption {
      type = types.port;
      default = 8080;
      description = "Listening port.";
    };

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
    users.users = optionalAttrs (cfg.user == defaultUser) {
      ${defaultUser} = {
        isSystemUser = true;
        group = defaultUser;
      };
    };

    users.groups = optionalAttrs (cfg.group == defaultUser) {
      ${defaultUser} = { };
    };

    networking.firewall = mkIf cfg.openFirewall {
      allowedTCPPorts = [ cfg.port ];
    };

    systemd.services.termix-server = {
      description = "Termix Server";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      environment = {
        DATA_DIR = cfg.dataDir;
        PORT = toString cfg.port;
        NODE_ENV = "production";
      };
      serviceConfig = mkMerge [
        {
          User = if cfg.user == defaultUser then defaultUser else cfg.user;
          Group = if cfg.group == defaultUser then defaultUser else cfg.group;
          ExecStart = "${cfg.package}/bin/termix";
          PrivateTmp = true;
          Restart = "always";
          WorkingDirectory = cfg.dataDir;
          DynamicUser = if cfg.user == defaultUser then true else false;
          StateDirectory = if (cfg.dataDir == "/var/lib/termix") && (cfg.user == defaultUser) then "termix" else null;
        }
      ];
    };
  };
}
