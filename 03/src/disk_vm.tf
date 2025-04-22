# vm with many disks

## basical vars

variable "vm_many_disks_image_family" {
  type    = string
  default = "ubuntu-2004-lts"
}

variable "vm_many_disks_name" {
  type    = string
  default = "storage"
}

variable "vm_many_disks_platform_id" {
  type    = string
  default = "standard-v1"
}

variable "vm_many_disks_preemptible" {
  type    = bool
  default = true
}

variable "vm_many_disks_nat" {
  type    = bool
  default = true
}

variable "vm_many_disks_serial_port_enable" {
  type    = number
  default = 1
}


## resources

variable "vm_many_disks_resources" {
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
  ssh_vm_many_disks_pub_key = "ubuntu:${file("./ed25519_pub")}"
}


## os

data "yandex_compute_image" "vm_many_disks_os" {
  family = var.vm_many_disks_image_family
}


## disks

resource "yandex_compute_disk" "disks_for_vm_with_many_disks" {
  count = 3

  name     = "${var.vm_many_disks_name}-disk-${count.index}"
  type     = "network-hdd"
  size     = 1 # 1 Gb
  zone     = "ru-central1-a"
}


## vms

resource "yandex_compute_instance" "storage" {
  name = var.vm_many_disks_name
  platform_id = var.vm_many_disks_platform_id

  resources {
    cores         = var.vm_many_disks_resources.cores
    memory        = var.vm_many_disks_resources.memory
    core_fraction = var.vm_many_disks_resources.core_fraction
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.vm_many_disks_os.id
    }
  }

  dynamic "secondary_disk" {
    for_each = toset(yandex_compute_disk.disks_for_vm_with_many_disks[*].id)
    content {
      disk_id = secondary_disk.value
    }
  }

  scheduling_policy {
    preemptible = var.vm_many_disks_preemptible
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.develop.id
    nat       = var.vm_many_disks_nat
    security_group_ids = [yandex_vpc_security_group.example.id]
  }

  metadata = {
    serial-port-enable = var.vm_many_disks_serial_port_enable
    ssh-keys = local.ssh_vm_many_disks_pub_key
  }
}