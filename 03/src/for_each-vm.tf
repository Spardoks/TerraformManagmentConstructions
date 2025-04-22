# vms with for_each


## basical vars

variable "vm_for_each_image_family" {
  type    = string
  default = "ubuntu-2004-lts"
}

variable "vm_for_each_count_name" {
  type    = string
  default = "db"
}

variable "vm_for_each_platform_id" {
  type    = string
  default = "standard-v1"
}

variable "vm_for_each_preemptible" {
  type    = bool
  default = true
}

variable "vm_for_each_nat" {
  type    = bool
  default = true
}

variable "vm_for_each_serial_port_enable" {
  type    = number
  default = 1
}


## resources

variable "each_vm" {
  type = list(object({  vm_name=string, cpu=number, ram=number, disk_volume=number, core_fraction=number }))
  default = [
    { vm_name = "main", cpu = 2, ram = 2, disk_volume = 10, core_fraction = 5 },
    { vm_name = "replica", cpu = 2, ram = 2, disk_volume = 10, core_fraction = 5 }
  ]
}


## vm_ssh

locals {
  ssh_for_each_pub_key = "ubuntu:${file("./ed25519_pub")}"
}


## os

data "yandex_compute_image" "vm_for_each_os" {
  family = var.vm_for_each_image_family
}


## vms

resource "yandex_compute_instance" "db" {
  # for_each = {
  #  main = {
  #    vm_name = "main"
  #    cpu     = 2
  #    ram     = 2
  #    disk_volume = 10
  #    core_fraction = 5
  #  },
  #  replica = {
  #    vm_name = "replica"
  #    cpu     = 2
  #    ram     = 2
  #    disk_volume = 10
  #    core_fraction = 5
  #  }
  # }

  for_each = { for vm in var.each_vm: vm.vm_name => vm }

  name = each.value.vm_name

  resources {
    cores         = each.value.cpu
    memory        = each.value.ram
    core_fraction = each.value.core_fraction
  }

  platform_id = var.vm_for_each_platform_id

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.vm_for_each_os.id
      size     = each.value.disk_volume
    }
  }

  scheduling_policy {
    preemptible = var.vm_for_each_preemptible
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.develop.id
    nat       = var.vm_for_each_nat
    security_group_ids = [yandex_vpc_security_group.example.id]
  }

  metadata = {
    serial-port-enable = var.vm_for_each_serial_port_enable
    ssh-keys = local.ssh_for_each_pub_key
  }
}