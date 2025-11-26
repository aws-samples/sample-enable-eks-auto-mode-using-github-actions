terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

variable "github_repository" {
  description = "GitHub repository in format owner/repo"
  type        = string
  default     = "aws-samples/sample-enable-eks-auto-mode-using-github-actions"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}
 # add the S3 bucket name for backups
variable "s3_bucket" {
  description = "S3 bucket name for backups"
  type        = string
  
}




data "aws_caller_identity" "current" {}

resource "aws_iam_openid_connect_provider" "github_actions" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  
}

resource "aws_iam_policy" "eks_policy" {
  name        = "GitHubActionsEKSPolicy"
  description = "Policy for GitHub Actions to manage EKS Auto Mode"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "EKSClusterManagement"
        Effect = "Allow"
        Action = [
          "eks:DescribeCluster",
          "eks:UpdateClusterConfig",
          "eks:ListNodegroups",
          "eks:DescribeNodegroup",
          "eks:ListClusters",
          "eks:DeleteNodegroup",
          "eks:CreateAccessEntry",
          "eks:DescribeAccessEntry",
          "eks:ListAccessEntries"
        ]
        Resource = [
          "arn:aws:eks:${var.aws_region}:${data.aws_caller_identity.current.account_id}:cluster/*",
          "arn:aws:eks:${var.aws_region}:${data.aws_caller_identity.current.account_id}:nodegroup/*/*/*",
          "arn:aws:eks:${var.aws_region}:${data.aws_caller_identity.current.account_id}:access-entry/*/*/*"

        ]
      },
      {
        Sid    = "IAMRoleManagement"
        Effect = "Allow"
        Action = [
          "iam:ListAttachedRolePolicies",
          "iam:CreateRole",
          "iam:GetRole",
          "iam:AttachRolePolicy",
          "iam:PassRole"
        ]
        Resource = [
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/AmazonEKSAutoNodeRole",
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/*"
        ]
      },
      {
        Sid    = "EC2NetworkManagement"
        Effect = "Allow"
        Action = [
          "ec2:DescribeSubnets",
          "ec2:CreateTags"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:RequestedRegion" = var.aws_region
          }
        }
      },
      {
        Sid    = "S3BackupAccess"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::${var.s3_bucket}",
          "arn:aws:s3:::${var.s3_bucket}/*"
        ]
        Condition = {
        StringEquals = {
          "s3:x-amz-server-side-encryption" = "AES256"
        }
        StringLike = {
          "s3:prefix" = ["backups/${var.github_repository}/*"]
        }
      }
      }
    ]
  })
}
 

resource "aws_iam_role" "github_actions_eks_role" {
  name        = "GitHubActionsEKSRole"
  description = "Role for GitHub Actions to manage EKS Auto Mode"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/token.actions.githubusercontent.com"
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:${var.github_repository}:*"
          }
        }
      }
    ]
  })

  

  
}

resource "aws_iam_role_policy_attachment" "attach_eks_policy" {
  role       = aws_iam_role.github_actions_eks_role.name
  policy_arn = aws_iam_policy.eks_policy.arn
}

# Output the role ARN for use in GitHub Actions
output "github_actions_role_arn" {
  description = "ARN of the GitHub Actions role"
  value       = aws_iam_role.github_actions_eks_role.arn
}

