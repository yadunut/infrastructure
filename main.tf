# [[file:Readme.org::*Setup Terraform][Setup Terraform:1]]
terraform {
  required_providers {
    digitalocean = {
      source = "digitalocean/digitalocean"
      version = "2.32.0"
    }
    ansible = {
      source = "ansible/ansible"
      version = "1.1.0"
    }
    external = {
      source = "hashicorp/external"
      version = "2.3.2"
    }
    cloudflare = {
      source = "cloudflare/cloudflare"
      version = "4.20.0"
    }
    local = {
      source = "hashicorp/local"
      version = "2.4.1"
    }
    proxmox = {
      source = "Telmate/proxmox"
      version = "2.9.14"
    }
  }
}

provider "cloudflare" {
  api_token = var.cf_token
}

provider "digitalocean" {
  token = var.do_token
}

provider "proxmox" {}
# Setup Terraform:1 ends here

# [[file:Readme.org::*Setup Terraform][Setup Terraform:3]]
resource "digitalocean_ssh_key" "yadunut" {
  name = "yadunut"
  public_key = var.ssh_public_key
  lifecycle {
    prevent_destroy = true
  }
}
# Setup Terraform:3 ends here

# [[file:Readme.org::*Spin up digital ocean server][Spin up digital ocean server:1]]
resource "digitalocean_droplet" "infranut_SGP1" {
  image  = "ubuntu-22-04-x64"
  name   = "infranut-SGP1"
  region = "SGP1"
  size   = "s-1vcpu-1gb"
  ssh_keys = [digitalocean_ssh_key.yadunut.id]
}
# Spin up digital ocean server:1 ends here

# [[file:Readme.org::*Assign domains to the server][Assign domains to the server:1]]
resource "cloudflare_record" "ts" {
  zone_id = var.cf_zone
  name = "ts"
  type = "A"
  value = digitalocean_droplet.infranut_SGP1.ipv4_address
  proxied = false
}
# Assign domains to the server:1 ends here

# [[file:Readme.org::*Setup server with ansible][Setup server with ansible:3]]
resource "ansible_playbook" "setup_offsite" {
  playbook = "ansible/setup-offsite.yml"
  # replayable = false
  name = digitalocean_droplet.infranut_SGP1.ipv4_address
  replayable = false
  verbosity = 5
  extra_vars = {
    created_username = var.username
    ssh_key = "'${var.ssh_public_key}'"
    headscale_hostname = cloudflare_record.ts.hostname
    headscale_port = 444
  }
}
# Setup server with ansible:3 ends here

# [[file:Readme.org::*Setup Headscale users][Setup Headscale users:1]]
data "local_file" "hs_apikey" {
  filename = "${path.module}/headscale.env"
  depends_on = [ ansible_playbook.setup_offsite ]
}

module "headscale" {
  source = "./modules/headscale"
  apikey = data.local_file.hs_apikey.content
  endpoint = "http://${cloudflare_record.ts.hostname}:444"
}
# Setup Headscale users:1 ends here

# [[file:Readme.org::*Setup Headscale users][Setup Headscale users:3]]
resource "ansible_playbook" "setup_tailscale" {
  playbook = "ansible/setup-tailscale.yml"
  replayable = false
  extra_vars = {
    hostname = cloudflare_record.ts.hostname
    auth_key = module.headscale.infra_key.key
    created_username = var.username
  }
  name = each.key
  for_each = toset(concat(var.proxmox_servers, tolist([digitalocean_droplet.infranut_SGP1.ipv4_address])))
}
# Setup Headscale users:3 ends here

# [[file:Readme.org::*Proxmox Nomad Servers][Proxmox Nomad Servers:1]]
resource "proxmox_vm_qemu" "nomad-server" {
  for_each    = toset(["eagle", "falcon"])
  name        = "nomad-server-${each.key}"
  target_node = each.key
  clone       = "ubuntu-2204-cloud-init"
  agent       = 1
  full_clone  = true
  onboot      = true

  tags = "nomad-server"

  memory = 2048
  cores  = 2
  scsihw = "virtio-scsi-single" # If i dont have this, the defaults override the cloned info

  qemu_os = "l26"

  sshkeys = digitalocean_ssh_key.yadunut.public_key
  ipconfig0 = "ip=dhcp,ip6=dhcp"
  ciuser = var.username

  network {
        bridge    = "vmbr0"
        firewall  = true
        link_down = false
        model     = "virtio"
        mtu       = 0
        queues    = 0
        rate      = 0
        tag       = -1
    }
  lifecycle {
    ignore_changes = [disk, network]
  }
}
# Proxmox Nomad Servers:1 ends here

# [[file:Readme.org::*Proxmox Nomad Servers][Proxmox Nomad Servers:3]]
resource "ansible_playbook" "setup_proxmox_servers" {
  playbook = "ansible/setup-proxmox-servers.yml"
  replayable = false
  extra_vars = {
    hs_hostname = cloudflare_record.ts.hostname
    auth_key = module.headscale.server_key.key
    created_username = var.username
    hs_port = 444
  }
  name = each.value.default_ipv4_address
  for_each = proxmox_vm_qemu.nomad-server
}
# Proxmox Nomad Servers:3 ends here

# [[file:Readme.org::*Setup Proxmox Nomad Clients][Setup Proxmox Nomad Clients:1]]
resource "proxmox_vm_qemu" "nomad-client" {
  for_each    = { for val in setproduct(["falcon", "eagle"], [1, 2]): "${val[0]}-${val[1]}" => val }
  name        = "nomad-client-${each.key}"
  target_node = each.value[0]
  clone       = "ubuntu-2204-cloud-init"
  agent       = 1
  full_clone  = true
  onboot      = true

  tags = "nomad-client"

  memory = 2048
  cores  = 2
  scsihw = "virtio-scsi-single" # If i dont have this, the defaults override the cloned info

  qemu_os = "l26"

  sshkeys = digitalocean_ssh_key.yadunut.public_key
  ipconfig0 = "ip=dhcp,ip6=dhcp"
  ciuser = var.username

  network {
        bridge    = "vmbr0"
        firewall  = true
        link_down = false
        model     = "virtio"
        mtu       = 0
        queues    = 0
        rate      = 0
        tag       = -1
    }
  lifecycle {
    ignore_changes = [disk, network]
  }
}
# Setup Proxmox Nomad Clients:1 ends here

# [[file:Readme.org::*Setup Proxmox Nomad Clients][Setup Proxmox Nomad Clients:3]]
resource "ansible_playbook" "setup_proxmox_clients" {
  playbook = "ansible/setup-proxmox-clients.yml"
  replayable = false
  extra_vars = {
    hs_hostname = cloudflare_record.ts.hostname
    auth_key = module.headscale.server_key.key
    created_username = var.username
    hs_port = 444
  }
  name = each.value.default_ipv4_address
  for_each = proxmox_vm_qemu.nomad-client
}
# Setup Proxmox Nomad Clients:3 ends here
