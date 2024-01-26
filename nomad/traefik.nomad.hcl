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
        "traefik.http.routers.dashboard.service=api@internal",

        "traefik.http.routers.temp-router.rule=Host(`tempRouter.ts.yadunut.com`)",
        "traefik.http.routers.temp-router.tls=true",
        "traefik.http.routers.temp-router.tls.domains[0].main=ts.yadunut.com",
        "traefik.http.routers.temp-router.tls.domains[0].sans=*.ts.yadunut.com",
        "traefik.http.routers.temp-router.tls.certresolver=myresolver",
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

          "--certificatesresolvers.myresolver.acme.email=cert@yadunut.com",
          "--certificatesresolvers.myresolver.acme.storage=acme.json",
          "--certificatesresolvers.myresolver.acme.dnschallenge.provider=cloudflare",
          #
          "--api.dashboard=true",
          "--log.level=DEBUG",
        ]
      }
      template {
        data = <<EOH
        CLOUDFLARE_EMAIL={{ with nomadVar "nomad/jobs/traefik" }}{{ .CLOUDFLARE_EMAIL }}{{ end }}
        CLOUDFLARE_API_KEY={{ with nomadVar "nomad/jobs/traefik" }}{{ .CLOUDFLARE_API_KEY }}{{ end }}
        EOH
        env = true
        destination = "local/env.env"
      }
    }
  }
}
# Change headscale to use traefik:2 ends here
