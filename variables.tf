# [[file:Readme.org::*Setup Terraform][Setup Terraform:2]]
variable do_token {
  type=string
  sensitive=true
}
variable cf_token {
  type=string
  sensitive=true
}
variable cf_zone { type=string }
variable ssh_public_key { type=string }
variable headscale_tls_email { type=string }

variable proxmox_servers { type=list(string) }
variable username {
  type=string
  default = "yadunut"
}
# Setup Terraform:2 ends here
