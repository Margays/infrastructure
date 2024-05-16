terraform {
  required_providers {
    cloudflare = {
      source = "cloudflare/cloudflare"
      version = ">= 4.9.0"
    }
    random = {
      source = "hashicorp/random"
    }
  }
  required_version = ">= 0.13"
}

provider "cloudflare" {
  api_token    = var.cloudflare_token
}

resource "cloudflare_access_organization" "this" {
  account_id                         = var.cloudflare_account_id
  name                               = "Margays"
  auth_domain                        = "margays.cloudflareaccess.com"
  is_ui_read_only                    = false
  user_seat_expiration_inactive_time = ""
  auto_redirect_to_identity          = false

  custom_pages {
    forbidden = ""
    identity_denied = ""
  }

  login_design {
    background_color = "#ffffff"
    text_color       = ""
    logo_path        = ""
    header_text      = ""
    footer_text      = ""
  }
}

resource "random_password" "tunnel_secret" {
  length = 64
}

resource "cloudflare_tunnel" "this" {
  account_id = var.cloudflare_account_id
  name       = "main"
  secret     = base64sha256(random_password.tunnel_secret.result)
  config_src = "cloudflare"
}

resource "cloudflare_tunnel_route" "example" {
  account_id         = var.cloudflare_account_id
  tunnel_id          = cloudflare_tunnel.this.id
  network            = "192.168.1.0/24"
  comment            = "Private network route comment"
}

resource "cloudflare_access_group" "developers" {
  account_id = var.cloudflare_account_id
  name       = "Developers"

  include {
    email = ["test@example.com"]
  }
}

resource "cloudflare_device_settings_policy" "developer_warp_policy" {
  account_id            = var.cloudflare_account_id
  name                  = "Developers WARP"
  description           = "Developers WARP settings policy description"
  precedence            = 10
  match                 = "any(identity.groups.name[*] in {\"Developers\"})"
  default               = false
  enabled               = true
  allow_mode_switch     = false
  allow_updates         = false
  allowed_to_leave      = true
  auto_connect          = 0
  captive_portal        = 180
  disable_auto_fallback = false
  support_url           = ""
  switch_locked         = false
  service_mode_v2_mode  = "warp"
  service_mode_v2_port  = 3000
  exclude_office_ips    = false
}

locals {
  exclude_addresses = {
    "ff05::/16": "",
    "ff04::/16": "",
    "ff03::/16": "",
    "ff02::/16": "",
    "ff01::/16": "",
    "fe80::/10": "IPv6 Link Local",
    "fd00::/8": "IPv6 Unique Local Unicast",
    "255.255.255.255/32": "IPv4 Broadcast",
    "240.0.0.0/4": "IPv4 Reserved",
    "224.0.0.0/24": "IPv4 Multicast",
    "192.0.0.0/24": "IPv4 IETF Protocol Assignments",
    "172.16.0.0/12": "IPv4 Private",
    "169.254.0.0/16": "IPv4 Link Local",
    "100.64.0.0/10": "IPv4 Shared Address Space",
    "10.0.0.0/8": "IPv4 Private",
  }
}

resource "cloudflare_split_tunnel" "example_device_settings_policy_split_tunnel_exclude" {
  account_id = var.cloudflare_account_id
  policy_id  = cloudflare_device_settings_policy.developer_warp_policy.id
  mode       = "exclude"

  dynamic "tunnels" {
    for_each = local.exclude_addresses
    content {
      address = tunnels.key
      description = tunnels.value
    }
  }
}
