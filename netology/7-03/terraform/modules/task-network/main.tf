# VPC Network and Subnet
resource "yandex_vpc_network" "network" {
  name = "netology"
}

resource "yandex_vpc_gateway" "nat_gateway" {
  name = "netology-gateway"
  shared_egress_gateway {}
}

resource "yandex_vpc_route_table" "route_table" {
  name       = "netology-route-table"
  network_id = yandex_vpc_network.network.id

  static_route {
    destination_prefix = "0.0.0.0/0"
    gateway_id         = yandex_vpc_gateway.nat_gateway.id
  }
}

resource "yandex_vpc_subnet" "subnet" {
  name           = "netology-subnet"
  zone           = var.zone
  network_id     = yandex_vpc_network.network.id
  v4_cidr_blocks = ["10.0.1.0/24"]
  route_table_id = yandex_vpc_route_table.route_table.id
}

# Security Groups
resource "yandex_vpc_security_group" "sg_LAN" {
  name       = "LAN-sg"
  network_id = yandex_vpc_network.network.id

  ingress {
    description    = "Allow internal traffic"
    protocol       = "ANY"
    v4_cidr_blocks = ["10.0.0.0/8"]
    from_port      = 0
    to_port        = 65535
  }

  egress {
    description    = "Allow all outbound"
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port      = 0
    to_port        = 65535
  }
}

resource "yandex_vpc_security_group" "sg_bastion" {
  name       = "bastion-sg"
  network_id = yandex_vpc_network.network.id

  ingress {
    description    = "Allow SSH from anywhere"
    protocol       = "TCP"
    port           = 22
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description    = "Allow all outbound"
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port      = 0
    to_port        = 65535
  }
}

resource "yandex_vpc_security_group" "sg_web" {
  name       = "web-sg"
  network_id = yandex_vpc_network.network.id

  ingress {
    description    = "Allow HTTP"
    protocol       = "TCP"
    port           = 80
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description    = "Allow HTTPS"
    protocol       = "TCP"
    port           = 443
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "yandex_vpc_security_group" "sg_traefik" {
  name       = "traefik-sg"
  network_id = yandex_vpc_network.network.id

  # Allow HTTP from anywhere
  ingress {
    description    = "Allow HTTP from Internet"
    protocol       = "TCP"
    port           = 80
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow HTTPS from anywhere
  ingress {
    description    = "Allow HTTPS from Internet"
    protocol       = "TCP"
    port           = 443
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow SSH only from local network only
  ingress {
    description    = "SSH from bastion only"
    protocol       = "TCP"
    port           = 22
    v4_cidr_blocks = ["10.0.0.0/8"]
  }

  # Outbound to private web servers only
  egress {
    description    = "Allow Traefik to reach web servers in private network"
    protocol       = "ANY"
    v4_cidr_blocks = ["10.0.0.0/8"]
    from_port      = 0
    to_port        = 65535
  }
}