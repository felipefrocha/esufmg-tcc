terraform {
  required_providers {
    helm = {
      source = "hashicorp/helm"
    }
  }
  backend "remote" {
    workspaces {
      prefix = "esufmg-tcc-"
    }
    organization = "raipe"
  }
}

provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
}


provider "kubernetes" {
  config_path = "~/.kube/config"
  # config_context = "my-context"
}

