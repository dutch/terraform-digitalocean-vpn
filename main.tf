terraform {
  required_providers {
    digitalocean = {
      source = "digitalocean/digitalocean"
      version = ">= 2.7.0"
    }
    wireguard = {
      source = "OJFord/wireguard"
      version = ">= 0.1.3"
    }
  }
}

locals {
  srcdir = "${path.module}/src"
  builddir = "${path.module}/${var.target_directory}"
}

provider "tls" {}

provider "local" {}

provider "wireguard" {}

provider "digitalocean" {
  token = var.digitalocean_token
}

resource "wireguard_asymmetric_key" "client" {}
resource "wireguard_asymmetric_key" "server" {}

data "wireguard_config_document" "server" {
  private_key = wireguard_asymmetric_key.server.private_key
  addresses = ["10.0.0.1/24"]
  listen_port = 51820
  post_up = [
    "iptables -A FORWARD -i %i -j ACCEPT",
    "iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE",
  ]
  pre_down = [
    "iptables -D FORWARD -i %i -j ACCEPT",
    "iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE",
  ]

  peer {
    public_key = wireguard_asymmetric_key.client.public_key
    allowed_ips = ["10.0.0.2/32"]
  }
}

resource "tls_private_key" "this" {
  algorithm = "RSA"
  rsa_bits = 4096
}

resource "digitalocean_droplet" "this" {
  image = "ubuntu-20-10-x64"
  name = var.droplet_name
  region = var.region
  size = "s-1vcpu-1gb"
  user_data = templatefile("${local.srcdir}/cloud-config.yml", {
    username = var.username
    public_key = tls_private_key.this.public_key_openssh
    config = indent(6, data.wireguard_config_document.server.conf)
    client_key = wireguard_asymmetric_key.client.public_key
  })

  connection {
    user = var.username
    host = self.ipv4_address
    private_key = tls_private_key.this.private_key_pem
  }

  provisioner "remote-exec" {
    inline = ["sudo cloud-init status --wait >/dev/null 2>&1"]
  }
}

data "wireguard_config_document" "client" {
  private_key = wireguard_asymmetric_key.client.private_key
  addresses = ["10.0.0.2/24"]
  dns = ["1.1.1.1"]

  peer {
    public_key = wireguard_asymmetric_key.server.public_key
    allowed_ips = ["0.0.0.0/0"]
    endpoint = "${digitalocean_droplet.this.ipv4_address}:51820"
  }
}
