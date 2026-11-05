data "aws_ssm_parameter" "ubuntu_ami" {
  name = var.ami_ssm_parameter
}

module "networking" {
  source = "./modules/networking"

  project_name       = var.project_name
  vpc_cidr           = var.vpc_cidr
  public_subnet_cidr = var.public_subnet_cidr
  availability_zone  = var.availability_zone
}

module "security" {
  source = "./modules/security"

  project_name      = var.project_name
  vpc_id            = module.networking.vpc_id
  allowed_http_cidr = var.allowed_http_cidr
}

module "iam" {
  source = "./modules/iam"

  project_name = var.project_name
}

module "ecr" {
  source = "./modules/ecr"

  project_name = var.project_name
}

module "ec2" {
  source = "./modules/ec2"

  project_name          = var.project_name
  ami_id                = data.aws_ssm_parameter.ubuntu_ami.value
  instance_type         = var.instance_type
  subnet_id             = module.networking.public_subnet_id
  security_group_id     = module.security.security_group_id
  instance_profile_name = module.iam.instance_profile_name
  root_volume_size      = var.root_volume_size

  user_data = file("${path.module}/bootstrap/ec2-user-data.sh")
}