# Seafile file sync, babbage's main job. Seafile's server is no longer packaged
# in nixpkgs, so this runs upstream's official container images (Seafile,
# MariaDB, Redis), following their Docker Compose setup without the parts sync
# does not need (Caddy, SeaDoc, the notification server).
#
# It is reachable only over the tailnet: Seafile listens on localhost, and
# `tailscale serve` publishes it with HTTPS at https://babbage.tailce49d3.ts.net.
#
# All state lives in plain directories under /var/lib/seafile, outside the
# container engine, so switching `virtualisation.oci-containers.backend` to
# docker recreates the same containers on the same data.
{
  config,
  lib,
  pkgs,
  ...
}:

let
  hostname = "babbage.tailce49d3.ts.net";
  state = "/var/lib/seafile";
  secrets = "${state}/secrets";
  network = "seafile-net";
  # Seafile's web server, bound to localhost only.
  port = 8000;

  backend = config.virtualisation.oci-containers.backend;
  engine =
    if backend == "podman" then
      lib.getExe config.virtualisation.podman.package
    else
      lib.getExe config.virtualisation.docker.package;
  serviceOf = name: "${backend}-${name}.service";
in
{
  virtualisation.podman.enable = true;
  virtualisation.oci-containers.backend = "podman";

  virtualisation.oci-containers.containers = {
    seafile-mysql = {
      image = "docker.io/library/mariadb:10.11.19";
      environment = {
        MYSQL_LOG_CONSOLE = "true";
        MARIADB_AUTO_UPGRADE = "1";
      };
      # MYSQL_ROOT_PASSWORD
      environmentFiles = [ "${secrets}/mysql.env" ];
      volumes = [ "${state}/mysql:/var/lib/mysql" ];
      networks = [ network ];
    };

    # A cache only: nothing is saved to disk.
    seafile-redis = {
      image = "docker.io/library/redis:8.2.11-alpine";
      entrypoint = "/bin/sh";
      cmd = [
        "-c"
        ''exec redis-server --requirepass "$REDIS_PASSWORD" --save "" --appendonly no''
      ];
      # REDIS_PASSWORD
      environmentFiles = [ "${secrets}/redis.env" ];
      networks = [ network ];
    };

    seafile = {
      image = "docker.io/seafileltd/seafile-mc:13.0.29";
      ports = [ "127.0.0.1:${toString port}:80" ];
      volumes = [ "${state}/data:/shared" ];
      environment = {
        SEAFILE_SERVER_HOSTNAME = hostname;
        SEAFILE_SERVER_PROTOCOL = "https";
        SITE_ROOT = "/";
        TIME_ZONE = config.time.timeZone;

        SEAFILE_MYSQL_DB_HOST = "seafile-mysql";
        SEAFILE_MYSQL_DB_PORT = "3306";
        SEAFILE_MYSQL_DB_USER = "seafile";
        SEAFILE_MYSQL_DB_CCNET_DB_NAME = "ccnet_db";
        SEAFILE_MYSQL_DB_SEAFILE_DB_NAME = "seafile_db";
        SEAFILE_MYSQL_DB_SEAHUB_DB_NAME = "seahub_db";

        CACHE_PROVIDER = "redis";
        REDIS_HOST = "seafile-redis";
        REDIS_PORT = "6379";

        # Used only when Seafile first starts, to create the administrator.
        INIT_SEAFILE_ADMIN_EMAIL = "admin@babbage.local";

        NON_ROOT = "false";
        SEAFILE_LOG_TO_STDOUT = "true";
        ENABLE_GO_FILESERVER = "true";
        ENABLE_SEADOC = "false";
        ENABLE_NOTIFICATION_SERVER = "false";
        NOTIFICATION_SERVER_URL = "https://${hostname}/notification";
        ENABLE_SEAFILE_AI = "false";
        ENABLE_FACE_RECOGNITION = "false";
      };
      # Database and Redis passwords, JWT key, initial administrator password.
      environmentFiles = [ "${secrets}/seafile.env" ];
      dependsOn = [
        "seafile-mysql"
        "seafile-redis"
      ];
      networks = [ network ];
    };
  };

  # Generates the passwords and keys on the first start (neither the repository
  # nor the Nix store contains them), and creates the containers' network.
  systemd.services.seafile-setup = {
    description = "Prepare Seafile's secrets and container network";
    before = map serviceOf [
      "seafile-mysql"
      "seafile-redis"
      "seafile"
    ];
    requiredBy = map serviceOf [
      "seafile-mysql"
      "seafile-redis"
      "seafile"
    ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      UMask = "0077";
    };
    path = [ pkgs.openssl ];
    script = ''
      mkdir -p ${state}/data ${state}/mysql ${secrets}
      if [ ! -e ${secrets}/seafile.env ]; then
        secret() { openssl rand -hex 32; }
        mysql_root=$(secret)
        redis=$(secret)
        jwt=$(secret)
        echo "MYSQL_ROOT_PASSWORD=$mysql_root" > ${secrets}/mysql.env
        echo "REDIS_PASSWORD=$redis" > ${secrets}/redis.env
        {
          echo "SEAFILE_MYSQL_DB_PASSWORD=$(secret)"
          echo "INIT_SEAFILE_MYSQL_ROOT_PASSWORD=$mysql_root"
          echo "REDIS_PASSWORD=$redis"
          echo "JWT_PRIVATE_KEY=$jwt"
          echo "SEAFILE_AI_SECRET_KEY=$jwt"
          echo "INIT_SEAFILE_ADMIN_PASSWORD=$(secret | cut -c1-24)"
        } > ${secrets}/seafile.env.tmp
        mv ${secrets}/seafile.env.tmp ${secrets}/seafile.env
      fi
      ${engine} network inspect ${network} >/dev/null 2>&1 \
        || ${engine} network create ${network}
    '';
  };

  # Publishes Seafile on the tailnet with HTTPS. `tailscale serve` keeps the
  # setting in Tailscale's state; rerunning it replaces the same mapping. It
  # fails until babbage is signed in and the tailnet allows HTTPS
  # certificates, so it retries.
  systemd.services.seafile-tailscale-serve = {
    description = "Publish Seafile on the tailnet";
    after = [
      "tailscaled.service"
      (serviceOf "seafile")
    ];
    wants = [ "tailscaled.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      Restart = "on-failure";
      RestartSec = 30;
    };
    script = ''
      ${lib.getExe config.services.tailscale.package} serve --bg --https=443 http://127.0.0.1:${toString port}
    '';
  };
}
