{
  name = "neo4j";

  nodes.server =
    { pkgs, ... }:
    {
      virtualisation.memorySize = 4096;
      virtualisation.diskSize = 1024;

      services.neo4j.enable = true;
      services.neo4j.plugins = [ pkgs.neo4j-apoc ];
      services.neo4j.extraServerConfig = ''
        dbms.security.procedures.unrestricted=apoc.*
        dbms.security.auth_enabled=false
      '';
      environment.etc."expected-apoc-version".text = pkgs.neo4j-apoc.version;
      # require tls certs to be available
      services.neo4j.https.enable = false;
      services.neo4j.bolt.enable = false;
    };

  testScript = ''
    start_all()

    server.wait_for_unit("neo4j.service")
    server.wait_for_open_port(7474)
    server.succeed("curl -f http://localhost:7474/")

    import json

    version = server.succeed("cat /etc/expected-apoc-version").strip()
    result = server.succeed(
        "curl --fail -H 'Content-Type: application/json' -d '{\"statements\":[{\"statement\":\"RETURN apoc.version()\"}]}' http://localhost:7474/db/neo4j/tx/commit"
    )
    row = json.loads(result)["results"][0]["data"][0]["row"]
    assert len(row) > 0
    remote_version = row[0]

    assert version.split(".")[:2] == remote_version.split(".")[:2]
  '';
}
