# [[file:../../Readme.org::*Setup Headscale users][Setup Headscale users:2]]
variable "apikey" { type=string }
variable "endpoint" { type=string }
terraform {
  required_providers {
    headscale = {
      source = "awlsring/headscale"
      version = "0.1.5"
    }
  }
}

provider "headscale" {
  endpoint = var.endpoint
  api_key = var.apikey
}

resource "headscale_user" "server" {
  name = "s"
}
resource "headscale_user" "personal" {
  name = "p"
}
resource "headscale_user" "infra" {
  name = "i"
}

resource "headscale_pre_auth_key" "server" {
  user = headscale_user.server.name
  reusable = true
  time_to_expire = "1y"

}
resource "headscale_pre_auth_key" "infra" {
  user = headscale_user.infra.name
  reusable = true
  time_to_expire = "1y"
}

output "server_key" {
  value = headscale_pre_auth_key.server
}
output "infra_key" {
  value = headscale_pre_auth_key.infra
}
# Setup Headscale users:2 ends here
