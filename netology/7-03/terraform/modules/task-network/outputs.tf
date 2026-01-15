output "subnet_id" {
  value = yandex_vpc_subnet.subnet.id
}

output "sg_LAN_id" {
  value = yandex_vpc_security_group.sg_LAN.id
}

output "sg_bastion_id" {
  value = yandex_vpc_security_group.sg_bastion.id
}

output "sg_web_id" {
  value = yandex_vpc_security_group.sg_web.id
}

output "sg_traefik_id" {
  value = yandex_vpc_security_group.sg_traefik.id
}