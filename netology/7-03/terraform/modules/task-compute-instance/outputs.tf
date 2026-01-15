output "public_ip" {
  value = yandex_compute_instance.task_compute_instance.*.network_interface.0.nat_ip_address[0]
}

output "private_ip" {
  value = yandex_compute_instance.task_compute_instance.*.network_interface.0.ip_address[0]
}
