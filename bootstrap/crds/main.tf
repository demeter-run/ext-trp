resource "kubernetes_manifest" "customresourcedefinition_trpports_demeter_run" {
  manifest = {
    "apiVersion" = "apiextensions.k8s.io/v1"
    "kind"       = "CustomResourceDefinition"
    "metadata" = {
      "name" = "trpports.demeter.run"
    }
    "spec" = {
      "group" = "demeter.run"
      "names" = {
        "categories" = [
          "demeter-port",
        ]
        "kind"   = "TrpPort"
        "plural" = "trpports"
        "shortNames" = [
          "trpports",
        ]
        "singular" = "trpport"
      }
      "scope" = "Namespaced"
      "versions" = [
        {
          "additionalPrinterColumns" = [
            {
              "jsonPath" = ".spec.network"
              "name"     = "Network"
              "type"     = "string"
            },
            {
              "jsonPath" = ".spec.throughputTier"
              "name"     = "Throughput Tier"
              "type"     = "string"
            },
            {
              "jsonPath" = ".status.endpointUrl"
              "name"     = "Endpoint URL"
              "type"     = "string"
            },
            {
              "jsonPath" = ".status.authenticatedEndpointUrl"
              "name"     = "Authenticated Endpoint URL"
              "type"     = "string"
            },
            {
              "jsonPath" = ".status.authToken"
              "name"     = "Auth Token"
              "type"     = "string"
            },
          ]
          "name" = "v1alpha1"
          "schema" = {
            "openAPIV3Schema" = {
              "description" = "Auto-generated derived type for TrpPortSpec via `CustomResource`"
              "properties" = {
                "spec" = {
                  "properties" = {
                    "authToken" = {
                      "type" = "string"
                    }
                    "network" = {
                      "type" = "string"
                    }
                    "throughputTier" = {
                      "type" = "string"
                    }
                  }
                  "required" = [
                    "authToken",
                    "network",
                    "throughputTier",
                  ]
                  "type" = "object"
                }
                "status" = {
                  "nullable" = true
                  "properties" = {
                    "authToken" = {
                      "type" = "string"
                    }
                    "authenticatedEndpointUrl" = {
                      "nullable" = true
                      "type"     = "string"
                    }
                    "endpointUrl" = {
                      "type" = "string"
                    }
                  }
                  "required" = [
                    "authToken",
                    "endpointUrl",
                  ]
                  "type" = "object"
                }
              }
              "required" = [
                "spec",
              ]
              "title" = "TrpPort"
              "type"  = "object"
            }
          }
          "served"  = true
          "storage" = true
          "subresources" = {
            "status" = {}
          }
        },
      ]
    }
  }
}
