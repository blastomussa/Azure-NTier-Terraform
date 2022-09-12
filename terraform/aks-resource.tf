# Kubernetes Deployment
resource "kubernetes_deployment" "api" {
  metadata {
    name = "flask-api"
    labels = {
      App = "FlaskAPI"
    }
  }

  spec {
    replicas = 4
    selector {
      match_labels = {
        App = "FlaskAPI"
      }
    }
    template {
      metadata {
        labels = {
          App = "FlaskAPI"
        }
      }
      spec {
        container {
          image = "testcontainer12359.azurecr.io/backend:ca1" #<<<<<<<<<<<<<<<<<<<-----------THIS NEEDS TO BE DYNAMIC
          name  = "api"

          port {
            container_port = 80
          }

          resources {
            limits = {
              cpu    = "0.5"
              memory = "512Mi"
            }
            requests = {
              cpu    = "250m"
              memory = "50Mi"
            }
          }
        }
      }
    }
  }
  depends_on = [azurerm_kubernetes_cluster.cluster]
}


# Kubernetes Service
resource "kubernetes_service" "api" {
  metadata {
    name = "flask-api"
  }
  spec {
    selector = {
      App = kubernetes_deployment.api.spec.0.template.0.metadata[0].labels.App
    }
    port {
      port        = 80
      target_port = 80
    }

    type = "LoadBalancer"
  }
  depends_on = [kubernetes_deployment.api]
}
