resource "kubernetes_cluster_role_v1" "operator" {
  metadata {
    name = "${var.namespace}-operator"
  }

  rule {
    api_groups = ["demeter.run"]
    resources  = ["trpports"]
    verbs      = ["get", "list", "watch", "patch"]
  }

  rule {
    api_groups = ["demeter.run"]
    resources  = ["trpports/status"]
    verbs      = ["patch"]
  }
}

resource "kubernetes_cluster_role_binding_v1" "operator" {
  metadata {
    name = "${var.namespace}-operator"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role_v1.operator.metadata[0].name
  }
  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account_v1.operator.metadata[0].name
    namespace = var.namespace
  }
}
