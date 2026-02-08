{
  system,
  pkgs,
  callTest,
}:
callTest (
  { nodes, ... }:
  {
    name = "termix-server";

    nodes = {
      server =
        { ... }:
        {
          services.termix-server = {
            enable = true;
            openFirewall = true;
          };
        };
    };

    testScript = ''
      server.start()
      server.wait_for_unit("termix-server.service")
      server.wait_for_open_port(30001)  # Health check port
      server.wait_for_open_port(30006)  # Dashboard API port
      # Wait for server to be fully ready
      server.sleep(5)

      # Test health check
      health_check = server.succeed("curl -I -s http://localhost:30001")
      assert "200 OK" in health_check, "Health check failed"

      print("✅ Termix server is running and healthy")
    '';
  }
)
