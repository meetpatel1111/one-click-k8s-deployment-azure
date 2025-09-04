/*
# Optional: deploy sample apps to AKS (mirrors your AWS kubernetes_deployment stubs)
# Requires the Kubernetes provider above to be configured (it is, via AKS kube_config)

resource "kubernetes_namespace" "apps" {
  metadata { name = "default" }
}

resource "kubernetes_deployment" "nginx" {
  metadata { name = "nginx" }
  spec {
    replicas = var.nginx_replicas
    selector { match_labels = { app = "nginx" } }
    template {
      metadata { labels = { app = "nginx" } }
      spec {
        container {
          name  = "nginx"
          image = "nginx:alpine"
          port { container_port = 80 }
        }
      }
    }
  }
}

resource "kubernetes_deployment" "nodejs_app" {
  metadata { name = "nodejs-app" }
  spec {
    replicas = var.nodejs_replicas
    selector { match_labels = { app = "nodejs-app" } }
    template {
      metadata { labels = { app = "nodejs-app" } }
      spec {
        container {
          name  = "nodejs-app"
          image = var.nodejs_docker_image
          port { container_port = 3000 }
        }
      }
    }
  }
}

resource "kubernetes_deployment" "mini_budget_tracker" {
  metadata { name = "mini-budget-tracker" }
  spec {
    replicas = var.mini_budget_tracker_replicas
    selector { match_labels = { app = "mini-budget-tracker" } }
    template {
      metadata { labels = { app = "mini-budget-tracker" } }
      spec {
        container {
          name  = "mini-budget-tracker"
          image = var.mini_budget_tracker_image
          port { container_port = 5173 }
        }
      }
    }
  }
}

resource "kubernetes_deployment" "retro_arcade_galaxy" {
  metadata { name = "retro-arcade-galaxy" }
  spec {
    replicas = var.retro_arcade_galaxy_replicas
    selector { match_labels = { app = "retro-arcade-galaxy" } }
    template {
      metadata { labels = { app = "retro-arcade-galaxy" } }
      spec {
        container {
          name  = "retro-arcade-galaxy"
          image = var.retro_arcade_docker_image
          port { container_port = 80 }
        }
      }
    }
  }
}

resource "kubernetes_deployment" "k8sgpt" {
  metadata { name = "k8sgpt" }
  spec {
    replicas = var.k8sgpt_replicas
    selector { match_labels = { app = "k8sgpt" } }
    template {
      metadata { labels = { app = "k8sgpt" } }
      spec {
        container {
          name  = "k8sgpt"
          image = "ghcr.io/k8sgpt-ai/k8sgpt:latest"
          port { container_port = 80 }
        }
      }
    }
  }
}
*/
