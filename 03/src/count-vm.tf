# vms with count


## basical vars

variable "vm_count_image_family" {
  type    = string
  default = "ubuntu-2004-lts"
}

variable "vm_count_name" {
  type    = string
  default = "web"
}

variable "vm_count_platform_id" {
  type    = string
  default = "standard-v1"
}

variable "vm_count_preemptible" {
  type    = bool
  default = true
}

variable "vm_count_nat" {
  type    = bool
  default = true
}

variable "vm_count_serial_port_enable" {
  type    = number
  default = 1
}


## resources

variable "vm_count_resources" {
  type = object({
    cores = number
    memory = number
    core_fraction = number
  })
  default = {
      cores = 2
      memory = 1
      core_fraction = 5
  }
}


## vm_ssh

locals {
  ssh_vm_count_pub_key = "ubuntu:${file("./ed25519_pub")}"
}


## os

data "yandex_compute_image" "vm_count_os" {
  family = var.vm_count_image_family
}


## vms

resource "yandex_compute_instance" "vms_count" {
  count = 2
  name = "${var.vm_count_name}-${count.index + 1}"
  platform_id = var.vm_count_platform_id

  resources {
    cores         = var.vm_count_resources.cores
    memory        = var.vm_count_resources.memory
    core_fraction = var.vm_count_resources.core_fraction
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.vm_count_os.id
    }
  }

  scheduling_policy {
    preemptible = var.vm_count_preemptible
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.develop.id
    nat       = var.vm_count_nat
    security_group_ids = [yandex_vpc_security_group.example.id]
  }

  metadata = {
    serial-port-enable = var.vm_count_serial_port_enable
    ssh-keys = local.ssh_vm_count_pub_key
  }

  depends_on = [yandex_compute_instance.db]
}