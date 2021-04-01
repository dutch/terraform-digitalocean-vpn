output "ipv4_address" {
  description = "The IPv4 address of the new VPN server."
  value = digitalocean_droplet.this.ipv4_address
}

output "client_config" {
  description = "The WireGuard configuration file for the client."
  value = data.wireguard_config_document.client
  sensitive = true
}

output "private_key" {
  description = "The SSH private key for connecting to the server."
  value = tls_private_key.this.private_key_pem
  sensitive = true
}
