# [[file:../Readme.org::*Change headscale to use traefik][Change headscale to use traefik:2]]
job "traefik" {
  datacenters = ["dc1"]

  group "traefik" {
    count = 1
    network {
      port "http" {
        static = 80
        host_network = "public"
      }

      port "https" {
        static = 443
        host_network = "public"
      }
      port "priv-http" {
        static = 80
      }

      port "priv-https" {
        static = 443
      }
    }
    service {
      name = "traefik"
      port = "80"
      tags = [
        "traefik.enable=true",
        "traefik.http.routers.dashboard.rule=(PathPrefix(`/api`) || PathPrefix(`/dashboard`))",
        "traefik.http.routers.dashboard.middlewares=tailscale",
        "traefik.http.middlewares.tailscale.ipwhitelist.sourcerange=172.17.0.0/16",
        "traefik.http.routers.dashboard.service=api@internal"
      ]
    }
    task "traefik" {
      driver = "docker"
      config {
        image = "traefik:2.10.7"
        ports = ["http", "https", "priv-http", "priv-https"]
        args = [
          "--entrypoints.http.address=:80",
          "--entrypoints.https.address=:443",

          "--providers.consulcatalog=true",
          "--providers.consulcatalog.endpoint.address=172.17.0.1:8500",
          "--providers.consulcatalog.prefix=traefik",
          "--providers.consulcatalog.exposedByDefault=false",

          # "--certificatesresolvers.myresolver.acme.email=cert@yadunut.com",
          # "--certificatesresolvers.myresolver.acme.storage=acme.json",
          # "--certificatesresolvers.myresolver.acme.httpchallenge.entrypoint=web",
          #
          # "--certificatesresolvers.myresolver.acme.dnschallenge.provider=cloudflare",
          #
          "--api.dashboard=true",
          "--log.level=DEBUG",
        ]
      }
      # env {
      #   CF_DNS_API_TOKEN = ""
      # }
    }
  }
}
# Change headscale to use traefik:2 ends here
