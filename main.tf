# Deploy Ubuntu

provider "aws" {
  region = var.aws_region
}

provider "google" {
  project = var.gcp_project
  region  = var.gcp_region
  zone    = "${var.gcp_region}-a"
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"]
}

resource "aws_key_pair" "host_key" {
  key_name   = "${var.environment_name}-key"
  public_key = var.ssh_key
}

resource "aws_vpc" "env_vpc" {
  cidr_block = var.cidr_block

  tags = {
    Name = "${var.environment_name}-vpc"
    Environment = var.environment_name
  }
}

resource "aws_internet_gateway" "env_gw" {
  vpc_id = aws_vpc.env_vpc.id

  tags = {
    Name = "${var.environment_name}-gw"
    Environment = var.environment_name
  }
}

resource "aws_route_table" "env_rt" {
  vpc_id = aws_vpc.env_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.env_gw.id
  }

  tags = {
    Name = "${var.environment_name}-rt"
    Environment = var.environment_name
  }
}

resource "aws_subnet" "env_subnet" {
  vpc_id     = aws_vpc.env_vpc.id
  cidr_block = var.subnet_block
  availability_zone = "${var.aws_region}a"
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.environment_name}-subnet-1"
    Environment = var.environment_name
  }
}

resource "aws_route_table_association" "env_rta" {
  subnet_id      = aws_subnet.env_subnet.id
  route_table_id = aws_route_table.env_rt.id
}

resource "aws_security_group" "env_sg" {
  name        = "allow_tls"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.env_vpc.id
  depends_on = [aws_vpc.env_vpc]

  ingress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = [aws_vpc.env_vpc.cidr_block]
  }

  ingress {
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "${var.environment_name}-sg"
    Environment = var.environment_name
  }
}

resource "google_compute_network" "gcp_net" {
  name = "${var.environment_name}-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "gcp_subnet" {
  name          = "${var.environment_name}-subnet"
  ip_cidr_range = var.subnet_block
  region        = var.gcp_region
  network       = google_compute_network.gcp_net.id
}

resource "google_compute_firewall" "gcp_fw_vpc" {
  name    = "${var.environment_name}-fw-vpc"
  network = google_compute_network.gcp_net.name

  allow {
    protocol = "all"
  }

  source_ranges = [var.cidr_block]
}

resource "google_compute_firewall" "gcp_fw_ext" {
  name    = "${var.environment_name}-fw-ext"
  network = google_compute_network.gcp_net.name

  allow {
    protocol = "tcp"
    ports    = ["22", "80", "443"]
  }

  source_ranges = ["0.0.0.0/0"]
}

resource "aws_instance" "ubuntu" {
  for_each      = var.environment_spec
  ami           = data.aws_ami.ubuntu.id
  instance_type = each.value.instance_type
  key_name      = aws_key_pair.host_key.key_name
  vpc_security_group_ids = [aws_security_group.env_sg.id]
  subnet_id              = aws_subnet.env_subnet.id
  availability_zone      = "${var.aws_region}a"

  root_block_device {
    volume_size = each.value.root_volume_size
    volume_type = each.value.root_volume_type
    iops        = each.value.root_volume_iops
  }

  ebs_block_device {
    device_name = "/dev/xvdb"
    volume_size = each.value.data_volume_size
    volume_type = each.value.data_volume_type
    iops        = each.value.data_volume_iops
  }

  tags = {
    Name = "${var.environment_name}-${each.key}"
  }
}

resource "google_compute_disk" "data_disk" {
  for_each     = var.environment_spec
  name         = "${each.key}-data"
  type         = each.value.gcp_disk_type
  size         = each.value.data_volume_size
  project      = var.gcp_project
  zone         = "${var.gcp_region}-a"
}

resource "google_service_account" "instance_sa" {
  account_id   = "${var.environment_name}-sa"
  display_name = "Service Account"
}

resource "google_compute_instance" "ubuntu" {
  for_each     = var.environment_spec
  name         = "${var.environment_name}-${each.key}"
  machine_type = each.value.gcp_machine_type
  zone         = "${var.gcp_region}-a"
  project      = var.gcp_project

  boot_disk {
    initialize_params {
      size = each.value.root_volume_size
      type = each.value.gcp_disk_type
      image = "ubuntu-os-cloud/ubuntu-2004-lts"
    }
  }

  attached_disk {
    source = google_compute_disk.data_disk[each.key].self_link
  }

  network_interface {
    subnetwork = google_compute_subnetwork.gcp_subnet.name
    subnetwork_project = var.gcp_project
    dynamic "access_config" {
      for_each = ["pub-ip"]
      content {}
    }
  }

  metadata = {
    ssh-keys = "ubuntu:${var.ssh_key}"
  }

  service_account {
    email = google_service_account.instance_sa.email
    scopes = ["cloud-platform"]
  }
}
