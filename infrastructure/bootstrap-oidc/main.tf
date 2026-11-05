provider "aws" {
  region = "eu-west-1"
}

data "aws_caller_identity" "current" {}

data "aws_iam_openid_connect_provider" "github" {
  arn = "arn:aws:iam::951614974272:oidc-provider/token.actions.githubusercontent.com"
}

data "aws_iam_policy_document" "github_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [data.aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:minddecoders@200070681/mern-ecommerce@1443862228:ref:refs/heads/master"]
    }
  }
}

resource "aws_iam_role" "github_terraform" {
  name                 = "mern-learning-github-actions-terraform"
  description          = "GitHub Actions Terraform role for mern-ecommerce"
  assume_role_policy   = data.aws_iam_policy_document.github_trust.json
  max_session_duration = 3600

  tags = {
    Project   = "mern-learning"
    ManagedBy = "Terraform"
  }
}

output "github_terraform_role_arn" {
  value = aws_iam_role.github_terraform.arn
}

output "github_oidc_provider_arn" {
  value = data.aws_iam_openid_connect_provider.github.arn
}

data "aws_iam_policy_document" "terraform_permissions" {

  # Terraform remote state and S3 lock file
  statement {
    sid    = "TerraformStateBucketList"
    effect = "Allow"

    actions = [
      "s3:ListBucket"
    ]

    resources = [
      "arn:aws:s3:::aws-ec2-autoscaling-devops-2026"
    ]

    condition {
      test     = "StringLike"
      variable = "s3:prefix"

      values = [
        "mern-learning/*"
      ]
    }
  }

  statement {
    sid    = "TerraformStateObjects"
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject"
    ]

    resources = [
      "arn:aws:s3:::aws-ec2-autoscaling-devops-2026/mern-learning/*"
    ]
  }

  # EC2 and VPC infrastructure in eu-west-1
  statement {
    sid    = "ManageRegionalEC2Infrastructure"
    effect = "Allow"

    actions = [
      "ec2:Describe*",
      "ec2:CreateVpc",
      "ec2:DeleteVpc",
      "ec2:ModifyVpcAttribute",
      "ec2:CreateSubnet",
      "ec2:DeleteSubnet",
      "ec2:ModifySubnetAttribute",
      "ec2:CreateInternetGateway",
      "ec2:DeleteInternetGateway",
      "ec2:AttachInternetGateway",
      "ec2:DetachInternetGateway",
      "ec2:CreateRouteTable",
      "ec2:DeleteRouteTable",
      "ec2:CreateRoute",
      "ec2:DeleteRoute",
      "ec2:AssociateRouteTable",
      "ec2:DisassociateRouteTable",
      "ec2:CreateSecurityGroup",
      "ec2:DeleteSecurityGroup",
      "ec2:AuthorizeSecurityGroupIngress",
      "ec2:AuthorizeSecurityGroupEgress",
      "ec2:RevokeSecurityGroupIngress",
      "ec2:RevokeSecurityGroupEgress",
      "ec2:RunInstances",
      "ec2:TerminateInstances",
      "ec2:CreateTags",
      "ec2:DeleteTags"
    ]

    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "aws:RequestedRegion"
      values   = ["eu-west-1"]
    }
  }

  # Project ECR repositories
  statement {
    sid    = "ManageMernECRRepositories"
    effect = "Allow"

    actions = [
      "ecr:CreateRepository",
      "ecr:DeleteRepository",
      "ecr:DescribeRepositories",
      "ecr:PutLifecyclePolicy",
      "ecr:GetLifecyclePolicy",
      "ecr:DeleteLifecyclePolicy",
      "ecr:TagResource",
      "ecr:UntagResource",
      "ecr:ListTagsForResource",
      "ecr:PutImageScanningConfiguration",
      "ecr:PutImageTagMutability"
    ]

    resources = [
      "arn:aws:ecr:eu-west-1:951614974272:repository/mern-learning-*"
    ]
  }

  # EC2 instance role and instance profile
  statement {
    sid    = "ManageMernEC2IAM"
    effect = "Allow"

    actions = [
      "iam:CreateRole",
      "iam:DeleteRole",
      "iam:DeleteRolePolicy",
       "iam:PutRolePolicy",
      "iam:GetRole",
      "iam:UpdateAssumeRolePolicy",
      "iam:TagRole",
      "iam:UntagRole",
      "iam:AttachRolePolicy",
      "iam:DetachRolePolicy",
      "iam:ListAttachedRolePolicies",
      "iam:CreateInstanceProfile",
      "iam:DeleteInstanceProfile",
      "iam:GetInstanceProfile",
      "iam:AddRoleToInstanceProfile",
      "iam:RemoveRoleFromInstanceProfile",
      "iam:TagInstanceProfile",
      "iam:UntagInstanceProfile",
      "iam:ListInstanceProfilesForRole"
    ]

    resources = [
      "arn:aws:iam::951614974272:role/mern-learning-ec2-ssm-role",
      "arn:aws:iam::951614974272:instance-profile/mern-learning-ec2-instance-profile"
    ]
  }

  # Read AWS-managed policies attached to the EC2 role
  statement {
    sid    = "ReadAWSManagedPolicies"
    effect = "Allow"

    actions = [
      "iam:GetPolicy",
      "iam:GetPolicyVersion"
    ]

    resources = [
      "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
      "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
    ]
  }

  # Pass only the MERN EC2 role to EC2
  statement {
    sid    = "PassOnlyMernEC2Role"
    effect = "Allow"

    actions = [
      "iam:PassRole"
    ]

    resources = [
      "arn:aws:iam::951614974272:role/mern-learning-ec2-ssm-role"
    ]

    condition {
      test     = "StringEquals"
      variable = "iam:PassedToService"
      values   = ["ec2.amazonaws.com"]
    }
  }

  # Read the official Ubuntu 22.04 AMI parameter
  statement {
    sid    = "ReadUbuntuAMIParameter"
    effect = "Allow"

    actions = [
      "ssm:GetParameter"
    ]

    resources = [
      "arn:aws:ssm:eu-west-1::parameter/aws/service/canonical/ubuntu/server/22.04/stable/current/amd64/hvm/ebs-gp2/ami-id"
    ]
  }

  # Terraform provider account identity check
  statement {
    sid    = "ReadAWSAccountIdentity"
    effect = "Allow"

    actions = [
      "sts:GetCallerIdentity"
    ]

    resources = ["*"]
  }
}

resource "aws_iam_policy" "terraform_permissions" {
  name        = "mern-learning-terraform-infrastructure-policy"
  description = "Terraform permissions for the MERN learning deployment"

  policy = data.aws_iam_policy_document.terraform_permissions.json

  tags = {
    Project   = "mern-learning"
    ManagedBy = "Terraform"
  }
}

resource "aws_iam_role_policy_attachment" "terraform_permissions" {
  role       = aws_iam_role.github_terraform.name
  policy_arn = aws_iam_policy.terraform_permissions.arn
}
