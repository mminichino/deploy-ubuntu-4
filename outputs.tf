output "aws-private" {
  value = [for instance in aws_instance.ubuntu: instance.private_ip]
}

output "aws-public" {
  value = [for instance in aws_instance.ubuntu: instance.public_ip]
}

output "gcp-private" {
  value = [for instance in google_compute_instance.ubuntu: instance.network_interface.0.network_ip]
}

output "gcp-public" {
  value = [for instance in google_compute_instance.ubuntu: instance.network_interface.0.access_config.0.nat_ip]
}
