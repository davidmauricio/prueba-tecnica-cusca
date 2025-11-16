variable "name" {
  type = string
}

variable "config_file" {
  type = string
}

resource "null_resource" "cluster" {
  triggers = {
    name        = var.name
    config_hash = filesha1(var.config_file)
  }

  # CREACIÓN DEL CLUSTER
  provisioner "local-exec" {
    command = "kind create cluster --name ${self.triggers.name} --config=${var.config_file}"
  }

  provisioner "local-exec" {
    when    = destroy
    command = "kind delete cluster --name ${self.triggers.name} || echo \"Cluster ${self.triggers.name} ya borrado\""
  }
}

output "kubectl_context" {
  value = "kind-${var.name}"
}