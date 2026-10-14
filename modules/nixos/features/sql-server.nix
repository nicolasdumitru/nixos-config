{ pkgs, ... }:

{
  virtualisation.oci-containers = {
    backend = "podman";
    containers.mssql = {
      image = "mcr.microsoft.com/mssql/server:2025-latest";
      environment = {
        ACCEPT_EULA = "Y";
        MSSQL_PID = "EnterpriseDeveloper";
      };
      environmentFiles = [ "/var/lib/mssql-secrets/environment" ];
      ports = [ "127.0.0.1:1433:1433" ];
      volumes = [ "mssql-data:/var/opt/mssql" ];
    };
  };

  # Generate once at runtime; neither the repository nor the Nix store contains
  # the SA password. Keep this file alongside the persistent database volume.
  systemd.services.mssql-credentials = {
    description = "Initialize SQL Server administrator credentials";
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      StateDirectory = "mssql-secrets";
      StateDirectoryMode = "0700";
      UMask = "0077";
    };
    script = ''
      if [ ! -e /var/lib/mssql-secrets/environment ]; then
        password="Aa1!$(${pkgs.openssl}/bin/openssl rand -hex 24)"
        printf 'MSSQL_SA_PASSWORD=%s\n' "$password" > /var/lib/mssql-secrets/environment.tmp
        mv /var/lib/mssql-secrets/environment.tmp /var/lib/mssql-secrets/environment
      fi
    '';
  };

  systemd.services.podman-mssql = {
    requires = [ "mssql-credentials.service" ];
    after = [ "mssql-credentials.service" ];
  };
}
