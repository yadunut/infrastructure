job "gitea" {
  datacenters = ["dc1"]
  group "gitea" {
    count = 1

    network {
      port "http" { to = 3000 }
      port "ssh" {
        static = 2222
        to = 22
      }
    }

    volume "gitea-data" {
      type = "host"
      source = "gitea-data"
      read_only = false
    }

    service {
      name = "gitea"
      port = "http"
      tags = [
        "traefik.enable=true",
        "traefik.http.routers.gitea.rule=Host(`gitea.ts.yadunut.com`)",
        "traefik.http.routers.gitea.tls=true",
        "traefik.http.routers.gitea.tls.certresolver=myresolver",
      ]
    }

    task "gitea" {
      driver = "docker"
      volume_mount {
        volume = "gitea-data"
        destination = "/data"
        read_only = false
      }

      config {
        image = "gitea/gitea:latest"
        ports = ["ssh", "http"]
      }

      env {
        USER_UID = "1000"
        USER_GID = "1000"
      }
    }
  }
}
