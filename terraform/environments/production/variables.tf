variable "project_name" {
  type = string
}

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
