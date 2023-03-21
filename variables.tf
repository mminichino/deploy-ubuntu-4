#

variable "aws_region" {
  description = "AWS region"
}

variable "gcp_region" {
  description = "AWS region"
}

variable "gcp_project" {
  description = "AWS region"
}

variable "gcp_service_account_email" {
  description = "The service account email"
}

variable "environment_name" {
  description = "Environment name"
}

variable "ssh_key" {
  description = "Admin SSH key"
}

variable "cidr_block" {
  description = "VPC CIDR"
}

variable "subnet_block" {
  description = "Subnet CIDR"
}

variable "environment_spec" {
  description = "Map of nodes"
  default     = {
    node-01 = {
      node_number     = 1,
      instance_type   = "t2.micro",
      gcp_machine_type = "e2‑small",
      root_volume_iops = "3000",
      root_volume_size = "50",
      root_volume_type = "gp3",
      gcp_disk_type    = "pd-ssd",
      data_volume_iops = "3000",
      data_volume_size = "100",
      data_volume_type = "gp3"
    }
    node-02 = {
      node_number     = 2,
      instance_type   = "t2.micro",
      gcp_machine_type = "e2‑small",
      root_volume_iops = "3000",
      root_volume_size = "50",
      root_volume_type = "gp3",
      gcp_disk_type    = "pd-ssd",
      data_volume_iops = "3000",
      data_volume_size = "100",
      data_volume_type = "gp3"
    }
    node-03 = {
      node_number     = 3,
      instance_type   = "t2.micro",
      gcp_machine_type = "e2‑small",
      root_volume_iops = "3000",
      root_volume_size = "50",
      root_volume_type = "gp3",
      gcp_disk_type    = "pd-ssd",
      data_volume_iops = "3000",
      data_volume_size = "100",
      data_volume_type = "gp3"
    }
  }
}
