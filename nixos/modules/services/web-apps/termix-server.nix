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

    enableNginx = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Whether to enable Nginx integration. If enabled, an Nginx virtual host
        will be created to serve the Termix web UI and reverse proxy API requests.
        If disabled, you must configure your own web server to serve the static
        files from `${cfg.package}/share/termix/html/dist` and proxy API requests
        to the backend services.
      '';
    };

    virtualHost = mkOption {
      type = types.str;
      default = "localhost";
      description = "The hostname at which Termix should be served.";
    };

    port = mkOption {
      type = types.port;
      default = 8080;
      description = "Port for the web UI (Nginx).";
    };

    enableSSL = mkOption {
      type = types.bool;
      default = false;
      description = "Enable SSL for the web UI.";
    };

    sslPort = mkOption {
      type = types.port;
      default = 8443;
      description = "Port for the SSL web UI.";
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
    networking.firewall = mkIf cfg.openFirewall {
      allowedTCPPorts = [
        (mkIf cfg.enableNginx cfg.port)
        (mkIf (cfg.enableNginx && cfg.enableSSL) cfg.sslPort)
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

    # Nginx configuration to serve Termix web UI
    services.nginx = mkIf cfg.enableNginx {
      enable = true;
      recommendedTlsSettings = mkDefault true;
      recommendedOptimisation = mkDefault true;
      recommendedGzipSettings = mkDefault true;
      virtualHosts.${cfg.virtualHost} = {
        listen = [
          { address = "0.0.0.0"; port = cfg.port; }
          (mkIf cfg.enableSSL { address = "0.0.0.0"; port = cfg.sslPort; ssl = true; })
        ];
        serverName = cfg.virtualHost;
        root = "${cfg.package}/share/termix/html/dist";
        
        locations."/" = {
          tryFiles = "$uri $uri/ /index.html";
        };

        locations."~* \\.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$" = {
          expires = "1y";
          addHeader = "Cache-Control public, immutable";
        };

        locations."~ ^/users/sessions(/.*)?" = {
          proxyPass = "http://127.0.0.1:30001";
          proxyHttpVersion = "1.1";
          proxySetHeaders = {
            Host = "$host";
            X-Real-IP = "$remote_addr";
            X-Forwarded-For = "$proxy_add_x_forwarded_for";
            X-Forwarded-Proto = "$scheme";
          };
        };

        locations."~ ^/users(/.*)?" = {
          proxyPass = "http://127.0.0.1:30001";
          proxyHttpVersion = "1.1";
          proxySetHeaders = {
            Host = "$host";
            X-Real-IP = "$remote_addr";
            X-Forwarded-For = "$proxy_add_x_forwarded_for";
            X-Forwarded-Proto = "$scheme";
          };
        };

        locations."~ ^/version(/.*)?" = {
          proxyPass = "http://127.0.0.1:30001";
          proxyHttpVersion = "1.1";
          proxySetHeaders = {
            Host = "$host";
            X-Real-IP = "$remote_addr";
            X-Forwarded-For = "$proxy_add_x_forwarded_for";
            X-Forwarded-Proto = "$scheme";
          };
        };

        locations."~ ^/releases(/.*)?" = {
          proxyPass = "http://127.0.0.1:30001";
          proxyHttpVersion = "1.1";
          proxySetHeaders = {
            Host = "$host";
            X-Real-IP = "$remote_addr";
            X-Forwarded-For = "$proxy_add_x_forwarded_for";
            X-Forwarded-Proto = "$scheme";
          };
        };

        locations."~ ^/alerts(/.*)?" = {
          proxyPass = "http://127.0.0.1:30001";
          proxyHttpVersion = "1.1";
          proxySetHeaders = {
            Host = "$host";
            X-Real-IP = "$remote_addr";
            X-Forwarded-For = "$proxy_add_x_forwarded_for";
            X-Forwarded-Proto = "$scheme";
          };
        };

        locations."~ ^/rbac(/.*)?" = {
          proxyPass = "http://127.0.0.1:30001";
          proxyHttpVersion = "1.1";
          proxySetHeaders = {
            Host = "$host";
            X-Real-IP = "$remote_addr";
            X-Forwarded-For = "$proxy_add_x_forwarded_for";
            X-Forwarded-Proto = "$scheme";
          };
        };

        locations."~ ^/credentials(/.*)?" = {
          proxyPass = "http://127.0.0.1:30001";
          proxyHttpVersion = "1.1";
          proxySetHeaders = {
            Host = "$host";
            X-Real-IP = "$remote_addr";
            X-Forwarded-For = "$proxy_add_x_forwarded_for";
            X-Forwarded-Proto = "$scheme";
          };
        };

        locations."~ ^/snippets(/.*)?" = {
          proxyPass = "http://127.0.0.1:30001";
          proxyHttpVersion = "1.1";
          proxySetHeaders = {
            Host = "$host";
            X-Real-IP = "$remote_addr";
            X-Forwarded-For = "$proxy_add_x_forwarded_for";
            X-Forwarded-Proto = "$scheme";
          };
        };

        locations."~ ^/terminal(/.*)?" = {
          proxyPass = "http://127.0.0.1:30001";
          proxyHttpVersion = "1.1";
          proxySetHeaders = {
            Host = "$host";
            X-Real-IP = "$remote_addr";
            X-Forwarded-For = "$proxy_add_x_forwarded_for";
            X-Forwarded-Proto = "$scheme";
          };
        };

        locations."~ ^/database(/.*)?" = {
          clientMaxBodySize = "5G";
          clientBodyTimeout = "300s";
          proxyPass = "http://127.0.0.1:30001";
          proxyHttpVersion = "1.1";
          proxySetHeaders = {
            Host = "$host";
            X-Real-IP = "$remote_addr";
            X-Forwarded-For = "$proxy_add_x_forwarded_for";
            X-Forwarded-Proto = "$scheme";
          };
        };

        locations."~ ^/db(/.*)?" = {
          clientMaxBodySize = "5G";
          clientBodyTimeout = "300s";
          proxyPass = "http://127.0.0.1:30001";
          proxyHttpVersion = "1.1";
          proxySetHeaders = {
            Host = "$host";
            X-Real-IP = "$remote_addr";
            X-Forwarded-For = "$proxy_add_x_forwarded_for";
            X-Forwarded-Proto = "$scheme";
          };
        };

        locations."~ ^/encryption(/.*)?" = {
          proxyPass = "http://127.0.0.1:30001";
          proxyHttpVersion = "1.1";
          proxySetHeaders = {
            Host = "$host";
            X-Real-IP = "$remote_addr";
            X-Forwarded-For = "$proxy_add_x_forwarded_for";
            X-Forwarded-Proto = "$scheme";
          };
        };

        locations."/ssh/quick-connect" = {
          proxyPass = "http://127.0.0.1:30001";
          proxyHttpVersion = "1.1";
          proxySetHeaders = {
            Host = "$host";
            X-Real-IP = "$remote_addr";
            X-Forwarded-For = "$proxy_add_x_forwarded_for";
            X-Forwarded-Proto = "$scheme";
            Upgrade = "$http_upgrade";
            Connection = "'upgrade'";
          };
        };

        locations."/ssh/" = {
          proxyPass = "http://127.0.0.1:30001";
          proxyHttpVersion = "1.1";
          proxySetHeaders = {
            Host = "$host";
            X-Real-IP = "$remote_addr";
            X-Forwarded-For = "$proxy_add_x_forwarded_for";
            X-Forwarded-Proto = "$scheme";
          };
        };

        locations."/ssh/websocket/" = {
          proxyPass = "http://127.0.0.1:30002/";
          proxyHttpVersion = "1.1";
          proxySetHeaders = {
            Host = "$host";
            X-Real-IP = "$remote_addr";
            X-Forwarded-For = "$proxy_add_x_forwarded_for";
            X-Forwarded-Proto = "$scheme";
            Upgrade = "$http_upgrade";
            Connection = "'upgrade'";
          };
        };

        locations."/ssh/tunnel/" = {
          proxyPass = "http://127.0.0.1:30003";
          proxyHttpVersion = "1.1";
          proxySetHeaders = {
            Host = "$host";
            X-Real-IP = "$remote_addr";
            X-Forwarded-For = "$proxy_add_x_forwarded_for";
            X-Forwarded-Proto = "$scheme";
          };
        };

        locations."/ssh/file_manager/recent" = {
          proxyPass = "http://127.0.0.1:30001";
          proxyHttpVersion = "1.1";
          proxySetHeaders = {
            Host = "$host";
            X-Real-IP = "$remote_addr";
            X-Forwarded-For = "$proxy_add_x_forwarded_for";
            X-Forwarded-Proto = "$scheme";
          };
        };

        locations."/ssh/file_manager/pinned" = {
          proxyPass = "http://127.0.0.1:30001";
          proxyHttpVersion = "1.1";
          proxySetHeaders = {
            Host = "$host";
            X-Real-IP = "$remote_addr";
            X-Forwarded-For = "$proxy_add_x_forwarded_for";
            X-Forwarded-Proto = "$scheme";
          };
        };

        locations."/ssh/file_manager/shortcuts" = {
          proxyPass = "http://127.0.0.1:30001";
          proxyHttpVersion = "1.1";
          proxySetHeaders = {
            Host = "$host";
            X-Real-IP = "$remote_addr";
            X-Forwarded-For = "$proxy_add_x_forwarded_for";
            X-Forwarded-Proto = "$scheme";
          };
        };

        locations."/ssh/file_manager/sudo-password" = {
          proxyPass = "http://127.0.0.1:30004";
          proxyHttpVersion = "1.1";
          proxySetHeaders = {
            Host = "$host";
            X-Real-IP = "$remote_addr";
            X-Forwarded-For = "$proxy_add_x_forwarded_for";
            X-Forwarded-Proto = "$scheme";
          };
        };

        locations."/ssh/file_manager/ssh/" = {
          clientMaxBodySize = "5G";
          clientBodyTimeout = "300s";
          proxyPass = "http://127.0.0.1:30004";
          proxyHttpVersion = "1.1";
          proxySetHeaders = {
            Host = "$host";
            X-Real-IP = "$remote_addr";
            X-Forwarded-For = "$proxy_add_x_forwarded_for";
            X-Forwarded-Proto = "$scheme";
          };
        };

        locations."~ ^/network-topology(/.*)?" = {
          proxyPass = "http://127.0.0.1:30001";
          proxyHttpVersion = "1.1";
          proxySetHeaders = {
            Host = "$host";
            X-Real-IP = "$remote_addr";
            X-Forwarded-For = "$proxy_add_x_forwarded_for";
            X-Forwarded-Proto = "$scheme";
          };
        };

        locations."/health" = {
          proxyPass = "http://127.0.0.1:30001";
          proxyHttpVersion = "1.1";
          proxySetHeaders = {
            Host = "$host";
            X-Real-IP = "$remote_addr";
            X-Forwarded-For = "$proxy_add_x_forwarded_for";
            X-Forwarded-Proto = "$scheme";
          };
        };

        locations."~ ^/status(/.*)?" = {
          proxyPass = "http://127.0.0.1:30005";
          proxyHttpVersion = "1.1";
          proxySetHeaders = {
            Host = "$host";
            X-Real-IP = "$remote_addr";
            X-Forwarded-For = "$proxy_add_x_forwarded_for";
            X-Forwarded-Proto = "$scheme";
          };
        };

        locations."~ ^/metrics(/.*)?" = {
          proxyPass = "http://127.0.0.1:30005";
          proxyHttpVersion = "1.1";
          proxySetHeaders = {
            Host = "$host";
            X-Real-IP = "$remote_addr";
            X-Forwarded-For = "$proxy_add_x_forwarded_for";
            X-Forwarded-Proto = "$scheme";
          };
        };

        locations."~ ^/uptime(/.*)?" = {
          proxyPass = "http://127.0.0.1:30006";
          proxyHttpVersion = "1.1";
          proxySetHeaders = {
            Host = "$host";
            X-Real-IP = "$remote_addr";
            X-Forwarded-For = "$proxy_add_x_forwarded_for";
            X-Forwarded-Proto = "$scheme";
          };
        };

        locations."~ ^/activity(/.*)?" = {
          proxyPass = "http://127.0.0.1:30006";
          proxyHttpVersion = "1.1";
          proxySetHeaders = {
            Host = "$host";
            X-Real-IP = "$remote_addr";
            X-Forwarded-For = "$proxy_add_x_forwarded_for";
            X-Forwarded-Proto = "$scheme";
          };
        };

        locations."~ ^/dashboard/preferences(/.*)?" = {
          proxyPass = "http://127.0.0.1:30006";
          proxyHttpVersion = "1.1";
          proxySetHeaders = {
            Host = "$host";
            X-Real-IP = "$remote_addr";
            X-Forwarded-For = "$proxy_add_x_forwarded_for";
            X-Forwarded-Proto = "$scheme";
          };
        };

        locations."^~ /docker/console/" = {
          proxyPass = "http://127.0.0.1:30008/";
          proxyHttpVersion = "1.1";
          proxySetHeaders = {
            Host = "$host";
            X-Real-IP = "$remote_addr";
            X-Forwarded-For = "$proxy_add_x_forwarded_for";
            X-Forwarded-Proto = "$scheme";
            Upgrade = "$http_upgrade";
            Connection = "'upgrade'";
          };
        };

        locations."~ ^/docker(/.*)?" = {
          proxyPass = "http://127.0.0.1:30007";
          proxyHttpVersion = "1.1";
          proxySetHeaders = {
            Host = "$host";
            X-Real-IP = "$remote_addr";
            X-Forwarded-For = "$proxy_add_x_forwarded_for";
            X-Forwarded-Proto = "$scheme";
          };
        };
      };
    };

    systemd.services.termix-server = {
      description = "Termix Server";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ] ++ (mkIf cfg.enableNginx [ "nginx.service" ]);
      requires = mkIf cfg.enableNginx [ "nginx.service" ];
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
