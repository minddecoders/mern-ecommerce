output "ec2_instance_id" {
  description = "EC2 instance ID"
  value       = module.ec2.instance_id
}

output "ec2_public_ip" {
  description = "EC2 public IPv4 address"
  value       = module.ec2.public_ip
}

output "website_url" {
  description = "Website URL"
  value       = "http://${module.ec2.public_ip}"
}

output "ecr_client_repository_url" {
  value = module.ecr.repository_urls["client"]
}

output "ecr_server_repository_url" {
  value = module.ecr.repository_urls["server"]
}

output "ssm_instance_profile" {
  value = module.iam.instance_profile_name
}