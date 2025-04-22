resource "local_file" "ansible_inventory" {
  content = templatefile("${path.module}/inventory.tftpl", {
    webservers = yandex_compute_instance.vms_count[*],
    databases  = values(yandex_compute_instance.db)[*],
    storage    = [yandex_compute_instance.storage]
  })
  filename = "${abspath(path.module)}/inventory.ini"
}
