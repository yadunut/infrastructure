job "whoami" {
  datacenters = ["dc1"]
  group "whoami" {
    count = 1

    network {
      port "http" {
        to = "8080"
      }
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
        image = "yadunut/whoami:v0.1"
        ports = ["http"]
      }
    }
  }
}
