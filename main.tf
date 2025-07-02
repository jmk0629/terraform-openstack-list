terraform {
  required_providers {
    http = {
      source  = "hashicorp/http"
      version = ">= 2.0.0"
    }
  }
}

# ─────────────────────────────────────────────
# 1) 변수 정의
# ─────────────────────────────────────────────
variable "auth_url"    { default = "http://mstsc.3hs.co.kr:50000/v3" }
variable "compute_url" { default = "http://mstsc.3hs.co.kr:8774/v2.1" }
variable "image_url"   { default = "http://mstsc.3hs.co.kr:9292/v2" }
variable "volume_url"  { default = "http://mstsc.3hs.co.kr:8776/v3" }
variable "network_url" { default = "http://mstsc.3hs.co.kr:9696/v2.0" }

variable "domain_name" { default = "default" }
variable "tenant_id"   { default = "656472d18ce84b95b16ee41bc6a36aac" }
variable "user_name"   { default = "admin" }
variable "password"    { default = "3hspassw0rd" }

# ─────────────────────────────────────────────
# 2) Keystone 토큰 발급
# ─────────────────────────────────────────────
data "http" "auth" {
  url    = "${var.auth_url}/auth/tokens"
  method = "POST"

  request_headers = {
    "Content-Type" = "application/json"
  }

  request_body = jsonencode({
    auth = {
      identity = {
        methods  = ["password"]
        password = {
          user = {
            name     = var.user_name
            domain   = { name = var.domain_name }
            password = var.password
          }
        }
      }
      scope = {
        project = { id = var.tenant_id }
      }
    }
  })
}

locals {
  # Keystone 응답 헤더에서 토큰 꺼내기
  auth_token = data.http.auth.response_headers["X-Subject-Token"]
}

# ─────────────────────────────────────────────
# 3) Nova: Flavor 리스트 조회
# ─────────────────────────────────────────────
data "http" "flavors" {
  url    = "${var.compute_url}/flavors/detail"
  method = "GET"
  request_headers = {
    "X-Auth-Token" = local.auth_token
  }
}

locals {
  all_flavors = jsondecode(data.http.flavors.response_body).flavors
}

output "all_flavors" {
  description = "모든 Flavor 리스트"
  value       = local.all_flavors
}

# ─────────────────────────────────────────────
# 4) Glance: Image 리스트 조회
# ─────────────────────────────────────────────
data "http" "images" {
  url    = "${var.image_url}/images"
  method = "GET"
  request_headers = {
    "X-Auth-Token" = local.auth_token
  }
}

locals {
  all_images = jsondecode(data.http.images.response_body).images
}

output "all_images" {
  description = "모든 Image 리스트"
  value       = local.all_images
}


# ─────────────────────────────────────────────
# 5) Cinder: Volume 리스트 조회
# ─────────────────────────────────────────────
data "http" "volumes" {
  url    = "${var.volume_url}/${var.tenant_id}/volumes/detail"
  method = "GET"
  request_headers = {
    "X-Auth-Token" = local.auth_token
  }
}

locals {
  all_volumes = jsondecode(data.http.volumes.response_body).volumes
}

output "all_volumes" {
  description = "모든 Volume 리스트"
  value       = local.all_volumes
}


# ─────────────────────────────────────────────
# 6) Neutron: Network 리스트 조회
# ─────────────────────────────────────────────
data "http" "networks" {
  url    = "${var.network_url}/networks"
  method = "GET"
  request_headers = {
    "X-Auth-Token" = local.auth_token
  }
}

locals {
  all_networks = jsondecode(data.http.networks.response_body).networks
}

output "all_networks" {
  description = "모든 Network 리스트"
  value       = local.all_networks
}


# ─────────────────────────────────────────────
# 7) Nova Server 리스트 조회
# ─────────────────────────────────────────────
data "http" "servers" {
  url    = "${var.compute_url}/servers/detail"
  method = "GET"
  request_headers = {
    "X-Auth-Token" = local.auth_token
  }
}

locals {
  all_servers = jsondecode(data.http.servers.response_body).servers
}

output "all_servers" {
  description = "모든 Server 리스트"
  value       = local.all_servers
}

# ─────────────────────────────────────────────
# 8) Keystone Service 리스트 조회
# ─────────────────────────────────────────────
data "http" "services" {
  url    = "${var.auth_url}/services"
  method = "GET"
  request_headers = {
    "X-Auth-Token" = local.auth_token
  }
}

locals {
  all_services = jsondecode(data.http.services.response_body).services
}

output "all_services" {
  description = "모든 Service 리스트"
  value       = local.all_services
}
