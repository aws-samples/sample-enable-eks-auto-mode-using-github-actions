
# EKS Auto Mode Enablement via GitHub Actions

## Overview
This project implements an automated solution for enabling Amazon EKS Auto Mode across multiple clusters using GitHub Actions. It addresses the challenges of manual compute resource management in EKS clusters by automating the enablement process through Infrastructure as Code (IaC).

## Prerequisites
- AWS Account
- GitHub Account
- Terraform installed locally
- AWS CLI
- EKS Clusters with Kubernetes version 1.29 or above

## Key Benefits
- **Consistency**: Uniform application of EKS Auto Mode across clusters
- **Efficiency**: Reduced manual effort and error potential
- **Scalability**: Easily adaptable for multiple clusters
- **Cost Optimization**: Better resource utilization through auto-scaling
- **Compliance**: Maintained adherence to organizational policies

## Implementation Steps

### 1. IAM Configuration
Deploy the IAM configuration using Terraform:
```terraform
terraform init
terraform plan
terraform apply
```

### 2. Repository Setup
```bash
git clone <repository-url>
cd eks-auto-mode-github-actions
```

### 3. Configuration
- Update the `.env` file with your AWS settings:
```env
AWS_REGION='us-east-1' # change as per your requirements
ROLE_NAME='arn:aws:iam::{account_id}:role/GitHubActionsEKSRole'
```

### 4. GitHub Actions Workflow
The workflow consists of two main jobs:
1. `check-clusters`: Identifies clusters without Auto Mode enabled
2. `enable-auto-mode`: Enables Auto Mode on identified clusters

## Architecture
![Architecture Diagram](/architecture.png)

The solution architecture involves:
- GitHub Actions for workflow automation
- AWS IAM for access management
- Amazon EKS for container orchestration

## Limitations
- Only supports EKS clusters with Kubernetes version 1.29 and above
- Requires appropriate IAM permissions
- Region-specific implementation

## Files Structure
```
.
├── .github/workflows/
│   └── auto-mode-pipeline.yml
├── .env
├── iam.tf
└── README.md
```

## Security Considerations
- Uses GitHub OIDC provider for secure AWS authentication
- Implements least privilege access through IAM roles
- Secure handling of AWS credentials
