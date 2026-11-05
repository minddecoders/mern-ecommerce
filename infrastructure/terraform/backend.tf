terraform {
  backend "s3" {
    bucket       = "aws-ec2-autoscaling-devops-2026"
    key          = "mern-learning/terraform.tfstate"
    region       = "eu-west-1"
    use_lockfile = true
  }
}