resource "kubernetes_stateful_set_v1" "trp" {
  wait_for_rollout = false

  metadata {
    name      = local.instance
    namespace = var.namespace
    labels = {
      "demeter.run/kind"            = "TrpInstance"
      "cardano.demeter.run/network" = var.network
      "demeter.run/instance"        = local.instance
    }
  }
  spec {
    replicas     = var.replicas
    service_name = "trp"

    selector {
      match_labels = {
        "demeter.run/instance"        = local.instance
        "cardano.demeter.run/network" = var.network
      }
    }
    template {
      metadata {
        labels = {
          "demeter.run/instance"        = local.instance
          "cardano.demeter.run/network" = var.network
        }
      }
      spec {
        init_container {
          name  = "init"
          image = "ghcr.io/txpipe/dolos:${var.dolos_version}"
          args = [
            "-c",
            "/etc/config/dolos.toml",
            "bootstrap",
            "snapshot",
            "--variant",
            "ledger",
          ]

          resources {
            limits   = var.resources.limits
            requests = var.resources.requests
          }

          volume_mount {
            name       = "config"
            mount_path = "/etc/config"
          }

          volume_mount {
            name       = "data"
            mount_path = "/var/data"
          }
        }

        container {
          name  = local.instance
          image = "ghcr.io/txpipe/dolos:${var.dolos_version}"
          args = [
            "-c",
            "/etc/config/dolos.toml",
            "daemon"
          ]
          resources {
            limits   = var.resources.limits
            requests = var.resources.requests
          }

          port {
            name           = "trp"
            container_port = 8000
            protocol       = "TCP"
          }

          volume_mount {
            name       = "data"
            mount_path = "/var/data"
          }

          volume_mount {
            name       = "config"
            mount_path = "/etc/config"
          }
        }

        volume {
          name = "data"
          persistent_volume_claim {
            claim_name = var.pvc_name
          }
        }

        volume {
          name = "config"
          config_map {
            name = "configs-${var.network}"
          }
        }

        termination_grace_period_seconds = 180
        dynamic "toleration" {
          for_each = var.tolerations

          content {
            effect   = toleration.value.effect
            key      = toleration.value.key
            operator = toleration.value.operator
            value    = toleration.value.value
          }
        }
      }
    }
  }
}

