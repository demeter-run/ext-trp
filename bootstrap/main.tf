resource "kubernetes_namespace" "namespace" {
  metadata {
    name = var.namespace
  }
}

module "configs" {
  depends_on = [kubernetes_namespace.namespace]
  source     = "./configs"
  for_each   = { for network in var.networks : "${network}" => network }

  namespace  = var.namespace
  network    = each.value
  address    = lookup(var.network_addresses, each.value, null)
  extra_fees = var.extra_fees
}

module "feature" {
  depends_on         = [kubernetes_namespace.namespace]
  source             = "./feature"
  namespace          = var.namespace
  operator_image_tag = var.operator_image_tag
  metrics_delay      = var.metrics_delay
  resources          = var.operator_resources
  tolerations        = var.operator_tolerations
  extension_domain   = var.extension_domain
  dns_names          = var.dns_names
}

module "proxies" {
  depends_on = [kubernetes_namespace.namespace]
  source     = "./proxy"
  for_each   = { for network in var.networks : "${network}" => network }

  network          = each.value
  proxy_image_tag  = var.proxy_image_tag
  namespace        = var.namespace
  replicas         = var.proxy_replicas
  resources        = var.proxy_resources
  tolerations      = var.proxy_tolerations
  cert_secret_name = var.cert_secret_name
  trp_instance     = var.trp_instance_per_network[each.key]
}

module "cells" {
  depends_on = [module.configs, module.feature]
  for_each   = var.cells
  source     = "./cell"

  namespace = var.namespace
  salt      = each.key
  tolerations = coalesce(each.value.tolerations, [
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
  ])

  // PVC
  storage_size  = each.value.pvc.storage_size
  storage_class = each.value.pvc.storage_class
  volume_name   = each.value.pvc.volume_name

  // Instances
  instances = each.value.instances
}

module "services" {
  depends_on = [kubernetes_namespace.namespace]
  for_each   = { for network in var.networks : "${network}" => network }
  source     = "./service"

  namespace = var.namespace
  network   = each.value
}
