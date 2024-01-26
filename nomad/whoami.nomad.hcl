job "whoami" {
  datacenters = ["dc1"]
  group "whoami" {
    count = 1

    network {
      port "http" {}
    }

    service {
      name = "whoami"
      port = "http"
      tags = [
        "traefik.enable=true",
        "traefik.http.routers.whoami.rule=Path(`/whoami`)",
        "traefik.http.routers.whoami.middlewares=tailscale",
      ]
    }
    task "whoami" {
      driver = "docker"
      config {
        image = "traefik/whoami"
        ports = ["http"]
      }

      env {
        WHOAMI_PORT_NUMBER = "${NOMAD_PORT_http}"
      }
    }
  }
}
