
# EKS Auto Mode Enablement via GitHub Actions

## Overview
This project implements an automated solution for enabling Amazon EKS Auto Mode across multiple clusters using GitHub Actions. It addresses the challenges of manual compute resource management in EKS clusters by automating the enablement process through Infrastructure as Code (IaC).

## Prerequisites

### 1. Required Accounts
- GitHub Account
- Create a Github Repository
- Active AWS Account with administrative permissions

### 2. Local Tools Installation
- Terraform (version 1.13.0 or higher)
- GitHub CLI (gh), configured with appropriate credentials
- kubectl and eksctl, configured for cluster management

### 3. EKS Cluster Requirements
- Kubernetes version 1.29 or above
- Endpoint access configuration:
  - Either "Public & Private" endpoints
  - Or Private endpoint with NAT Gateway in private subnets
- "EKS API and ConfigMap" cluster access enabled
- Active node groups or managed node pools

### 4. IAM OIDC Configuration Requirements
- IAM role with:
  - Trust policy for GitHub OIDC
  - Permissions for:
    - EKS Cluster management
    - S3 bucket access
    - IAM role management
    - EC2 network management
- Reference `iam.tf` for Terraform setup


## Key Benefits
- **Consistency**: Uniform application of EKS Auto Mode across clusters
- **Efficiency**: Reduced manual effort and error potential
- **Scalability**: Easily adaptable for multiple clusters
- **Cost Optimization**: Better resource utilization through auto-scaling
- **Compliance**: Maintained adherence to organizational policies

## Implementation Steps

### 1. IAM Configuration
Deploy the IAM configuration using Terraform to create the IAM resources if not present in account:
```terraform
terraform init
terraform plan
terraform apply
```

### 2. Repository Setup
```bash
git clone https://github.com/aws-samples/sample-enable-eks-auto-mode-using-github-actions.git
cd sample-enable-eks-auto-mode-using-github-actions
cp .github/workflows/enable-eks-auto-mode.yml /path/to/your/repository/.github/workflows
```
### 3. Push the changes to your repository
Commit the new workflow file and push to your repository
 
### 4. Configuration
- Update the git secrets for the repository:
```bash
gh auth login --web  #authenticate to your github account using web

#create secrets
gh secret set AWS_REGION --body "us-east-1" 

gh secret set AWS_ROLE_ARN --body "arn:aws:iam:ACCOUNT_ID:role/GitHubActionsEKSRole" 
#replace the account id with your account ID
```

### 5. GitHub Actions Workflow
The workflow consists of three main jobs:
1. `check-clusters`: Identifies clusters without Auto Mode enabled and updates IAM policies/subnet tags.
2. `backup-and-check`: Backs up cluster state before migration
3. `gradual-migration` : enables Auto Mode while gradually draining existing node groups and cleaning up old 
scaling components.

 
### 3. Resource Cleanup
### Detach IAM Role
To remove the IAM role from the aws-auth configmap, run:

```bash
eksctl delete iamidentitymapping \
  --cluster $cluster \
  --region $AWS_REGION \
  --arn $ROLE_ARN
```

## Architecture
![Architecture Diagram](/architecture.png)

The solution architecture involves:
- GitHub Actions for workflow automation
- AWS IAM for access management
- Amazon EKS for container orchestration

## Limitations
- Only supports EKS clusters with Kubernetes version 1.29 and above
- Only support Karpenter version 1.1.0 and above
- Requires appropriate IAM permissions
- Region-specific implementation
- Requires cluster endpoint accessibility
- Limited to AWS-managed node groups

## Files Structure
```
.
├── .github/workflows/
│   └── auto-mode-pipeline.yml
├── .scripts/
│    └── backup-cluster-state.sh
├── iam.tf
└── README.md
```

## Security Considerations
- Uses GitHub OIDC provider for secure AWS authentication
- Implements least privilege access through IAM roles
- Secure handling of AWS credentials
