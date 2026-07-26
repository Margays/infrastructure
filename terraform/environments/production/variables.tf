variable "proxmox_endpoint" {
  type = string
}

variable "proxmox_username" {
  type = string
}

variable "proxmox_password" {
  type = string
}

variable "proxmox_insecure" {
  type    = bool
  default = false
}

variable "config_path" {
  type = string
}
