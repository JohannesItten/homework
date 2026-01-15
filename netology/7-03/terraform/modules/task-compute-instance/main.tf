data "yandex_compute_image" "ubuntu_2404_lts" {
  family = "ubuntu-2404-lts"
}

resource "yandex_compute_instance" "task_compute_instance" {
  name        = var.instance_name
  hostname    = var.instance_name
  platform_id = "standard-v1"
  zone        = var.zone

  resources {
    cores         = 2
    memory        = 2
    core_fraction = 100
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu_2404_lts.image_id
      type     = "network-ssd"
      size     = 20
    }
  }

  metadata = {
    user-data          = file("${path.module}/cloud-init.yml")
    serial-port-enable = 1
  }

  scheduling_policy { preemptible = true }

  network_interface {
    subnet_id          = var.subnet_id
    nat                = var.is_nat
    security_group_ids = var.security_group_ids
  }
}