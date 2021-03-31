output "ipv4_address" {
  description = "The IPv4 address of the new VPN server."
  value = digitalocean_droplet.this.ipv4_address
}
