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

variable "s3_endpoint" {
  type    = string
  default = "http://s3.domain.local"
}

variable "s3_access_key" {
  type    = string
  default = "xxxxxxxxxxxx"
}

variable "s3_secret_key" {
  type    = string
  default = "xxxxxxxxxxxx"
}
