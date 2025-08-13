locals {
  default_address_by_network = {
    "cardano-mainnet" : "node-mainnet-stable.ext-nodes-m1.svc.cluster.local:3000"
    "cardano-preprod" : "node-preprod-stable.ext-nodes-m1.svc.cluster.local:3000"
    "cardano-preview" : "node-preview-stable.ext-nodes-m1.svc.cluster.local:3000"
  }
}

terraform {
  required_providers {
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
  }
}

variable "network" {
  description = "cardano node network"
}

variable "namespace" {
  description = "the namespace where the resources will be created"
}

variable "address" {
  type    = string
  default = null
}

variable "extra_fees" {
  type    = number
  default = 200000
}

resource "kubernetes_config_map" "node-config" {
  metadata {
    namespace = var.namespace
    name      = "configs-${var.network}"
  }

  data = {
    "dolos.toml" = "${templatefile("${path.module}/${var.network}.toml", {
      address    = coalesce(var.address, local.default_address_by_network[var.network])
      extra_fees = var.extra_fees
    })}"
  }
}

output "cm_name" {
  value = "configs-${var.network}"
}
