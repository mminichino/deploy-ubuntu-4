output "node-private" {
  value = [for instance in aws_instance.ubuntu: instance.private_ip]
}

output "node-public" {
  value = [for instance in aws_instance.ubuntu: instance.public_ip]
}
