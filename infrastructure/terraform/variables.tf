variable "project_name" {
  description = "Project resource name prefix"
  type        = string
  default     = "mern-learning"
}

variable "aws_region" {
  description = "AWS deployment region"
  type        = string
  default     = "eu-west-1"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "vpc_cidr" {
  description = "VPC CIDR"
  type        = string
  default     = "10.20.0.0/16"
}

variable "public_subnet_cidr" {
  description = "Public subnet CIDR"
  type        = string
  default     = "10.20.1.0/24"
}

variable "availability_zone" {
  description = "Availability zone for the EC2 subnet"
  type        = string
  default     = "eu-west-1a"
}

variable "allowed_http_cidr" {
  description = "Source CIDR allowed to access the website"
  type        = string
  default     = "0.0.0.0/0"
}

variable "ami_ssm_parameter" {
  description = "Canonical Ubuntu 22.04 AMI parameter"
  type        = string
  default     = "/aws/service/canonical/ubuntu/server/22.04/stable/current/amd64/hvm/ebs-gp2/ami-id"
}

variable "root_volume_size" {
  description = "EC2 root disk size in GiB"
  type        = number
  default     = 8
}