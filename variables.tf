variable "digitalocean_token" {
  type = string
  description = "The DigitalOcean access token to use for authentication."
  sensitive = true
}

variable "region" {
  type = string
  description = "The DigitalOcean region to which the instance should belong."
}

variable "target_directory" {
  type = string
  description = "The directory in which to store output files."
  default = "target"
}

variable "droplet_name" {
  type = string
  description = "The name for the new droplet."
  default = "vpn"
}

variable "username" {
  type = string
  description = "The user to create for SSH logins."
  default = "centos"
}
