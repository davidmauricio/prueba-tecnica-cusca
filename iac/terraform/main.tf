terraform {
  required_version = ">= 1.5.0"

  required_providers {
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
  }
}

provider "null" {}

module "deployment_cluster" {
  source      = "./modules/kind-cluster"
  name        = "deployment-cluster"
  config_file = abspath("${path.root}/../kind/deployment-cluster.yaml")
}

module "development_cluster" {
  source      = "./modules/kind-cluster"
  name        = "dev-cluster"
  config_file = abspath("${path.root}/../kind/development-cluster.yaml")
}

# Aplica los manifiestos del microservicio en el cluster de development
resource "null_resource" "apply_microservice_dev" {
  depends_on = [module.development_cluster]

  provisioner "local-exec" {
    command = "kubectl --context kind-dev-cluster apply -f \"${path.root}/../kubernetes/development/microservice/namespace.yaml\" && kubectl --context kind-dev-cluster apply -f \"${path.root}/../kubernetes/development/microservice/service.yaml\" && kubectl --context kind-dev-cluster apply -f \"${path.root}/../kubernetes/development/microservice/deployment.yaml\""
  }

  provisioner "local-exec" {
    when    = destroy
    command = "kubectl --context kind-dev-cluster delete -f \"${path.root}/../kubernetes/development/microservice\" --ignore-not-found=true"
  }
}

# Aplica Vault en el deployment cluster
resource "null_resource" "apply_vault" {
  depends_on = [module.deployment_cluster]

  provisioner "local-exec" {
    command = "kubectl --context kind-deployment-cluster apply -f \"${path.root}/../kubernetes/deployment/vault/namespace.yaml\" && kubectl --context kind-deployment-cluster apply -f \"${path.root}/../kubernetes/deployment/vault/service.yaml\" && kubectl --context kind-deployment-cluster apply -f \"${path.root}/../kubernetes/deployment/vault/deployment.yaml\" && kubectl --context kind-deployment-cluster apply -f \"${path.root}/../kubernetes/deployment/vault/job-seed-secret.yaml\""
  }

  provisioner "local-exec" {
    when    = destroy
    command = "kubectl --context kind-deployment-cluster delete -f \"${path.root}/../kubernetes/deployment/vault\" --ignore-not-found=true"
  }
}

# Aplica Jenkins en el deployment cluster
resource "null_resource" "apply_jenkins" {
  depends_on = [
    module.deployment_cluster,
    null_resource.apply_vault
  ]

  provisioner "local-exec" {
    command = "kubectl --context kind-deployment-cluster apply -f \"${path.root}/../kubernetes/deployment/jenkins/namespace.yaml\" && kubectl --context kind-deployment-cluster apply -f \"${path.root}/../kubernetes/deployment/jenkins\""
  }

  provisioner "local-exec" {
    when    = destroy
    command = "kubectl --context kind-deployment-cluster delete -f \"${path.root}/../kubernetes/deployment/jenkins\" --ignore-not-found=true"
  }
}
