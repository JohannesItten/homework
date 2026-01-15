locals {
  zone = "ru-central1-a"

  instances = {
    bastion = {
      name               = "bastion"
      security_group_ids = [module.network.sg_LAN_id, module.network.sg_bastion_id]
      is_nat             = true,
      subnet_id          = module.network.subnet_id
    }
    web_a = {
      name               = "web-a"
      security_group_ids = [module.network.sg_LAN_id, module.network.sg_web_id]
      is_nat             = false,
      subnet_id          = module.network.subnet_id
    }
    web_b = {
      name               = "web-b"
      security_group_ids = [module.network.sg_LAN_id, module.network.sg_web_id]
      is_nat             = false
      subnet_id          = module.network.subnet_id
    }
    traefik = {
      name               = "traefik"
      security_group_ids = [module.network.sg_LAN_id, module.network.sg_traefik_id]
      is_nat             = true,
      subnet_id          = module.network.subnet_id
    }
  }
}

module "network" {
  source = "./modules/task-network"
  zone   = local.zone
}

module "task_instance" {
  source             = "./modules/task-compute-instance"
  for_each           = local.instances
  instance_name      = each.value.name
  security_group_ids = each.value.security_group_ids
  is_nat             = each.value.is_nat
  subnet_id          = each.value.subnet_id
  zone               = local.zone
}

resource "local_file" "inventory" {
  content  = <<-EOF
  [bastion]
  ${module.task_instance["bastion"].public_ip}

  [traefik]
  ${module.task_instance["traefik"].private_ip}
  [traefik:vars]
  ansible_ssh_common_args='-o ProxyCommand="ssh -p 22 -W %h:%p -q ansible@${module.task_instance["bastion"].public_ip}"'

  [webservers]
  ${module.task_instance["web_a"].private_ip}
  ${module.task_instance["web_b"].private_ip}
  [webservers:vars]
  ansible_ssh_common_args='-o ProxyCommand="ssh -p 22 -W %h:%p -q ansible@${module.task_instance["bastion"].public_ip}"'
  EOF
  filename = "../ansible/hosts.ini"
}

resource "local_file" "group_vars" {
  content  = <<-EOF
  web_servers:
    - ip: ${module.task_instance["web_a"].private_ip}
      port: 80
    - ip: ${module.task_instance["web_b"].private_ip}
      port: 80
  EOF
  filename = "../ansible/group_vars/traefik-webservers.yml"
}