
output "arm_node_ips" {
  value = aws_instance.arm_vms.*.public_ip
}

output "multi_name" {
  value = aws_route53_record.k3s-multi.name
}
output "single_name" {
  value = aws_route53_record.k3s-single.name
}

output "all_node_ips" {
  value = concat(
    # aws_instance.ubuntu_vms.*.public_ip,
    aws_instance.arm_vms.*.public_ip,
	# aws_instance.gpu_vms.*.public_ip,
  )
}