variable "namespace" {
  type = string
}

variable "dns_zone" {
  type    = string
  default = "demeter.run"
}

variable "extension_domain" {
  type    = string
  default = "balius-m1.demeter.run"
}

variable "networks" {
  type    = list(string)
  default = ["mainnet", "preprod", "preview"]
}

variable "network_addresses" {
  type    = map(string)
  default = {}
}

variable "extra_fees" {
  type    = number
  default = 200000
}

// Operator
variable "operator_image_tag" {
  type = string
}

variable "metrics_delay" {
  type    = number
  default = 60
}

variable "operator_tolerations" {
  type = list(object({
    effect   = string
    key      = string
    operator = string
    value    = optional(string)
  }))
  default = [
    {
      effect   = "NoSchedule"
      key      = "demeter.run/compute-profile"
      operator = "Exists"
    },
    {
      effect   = "NoSchedule"
      key      = "demeter.run/compute-arch"
      operator = "Exists"
    },
    {
      effect   = "NoSchedule"
      key      = "demeter.run/availability-sla"
      operator = "Equal"
      value    = "consistent"
    }
  ]
}

variable "operator_resources" {
  type = object({
    limits = object({
      cpu    = string
      memory = string
    })
    requests = object({
      cpu    = string
      memory = string
    })
  })
  default = {
    limits = {
      cpu    = "1"
      memory = "512Mi"
    }
    requests = {
      cpu    = "50m"
      memory = "512Mi"
    }
  }
}

variable "cells" {
  type = map(object({
    tolerations = optional(list(object({
      effect   = string
      key      = string
      operator = string
      value    = optional(string)
    })))
    pvc = object({
      storage_class = string
      storage_size  = string
      volume_name   = optional(string)
    })
    instances = map(object({
      dolos_version = string
      replicas      = optional(number)
      resources = optional(object({
        limits = object({
          cpu    = string
          memory = string
        })
        requests = object({
          cpu    = string
          memory = string
        })
      }))
    }))
  }))
}
