# Multi-Environment Microservices Banking Application

> **Enterprise-grade microservices banking application deployed on AWS EKS with Terraform, Helm, and GitHub Actions CI/CD**

[![Terraform](https://img.shields.io/badge/Terraform-1.6+-blue.svg)](https://www.terraform.io/)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-1.28+-326CE5.svg)](https://kubernetes.io/)
[![Helm](https://img.shields.io/badge/Helm-3.12+-0F1689.svg)](https://helm.sh/)
[![AWS](https://img.shields.io/badge/AWS-EKS-FF9900.svg)](https://aws.amazon.com/eks/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

## Table of Contents

- [Architecture Overview](#architecture-overview)
- [Deployment Guide](#deployment-guide)
- [Troubleshooting](#troubleshooting)
- [Security Best Practices](#security-best-practices)
- [Cost Optimization](#cost-optimization)
- [Disaster Recovery](#disaster-recovery)
- [Additional Documentation](#additional-documentation)

---

## Architecture Overview

### System Architecture
<img width="1835" height="2369" alt="image" src="https://github.com/user-attachments/assets/f9451e8a-340b-481f-94db-92bc0f1c95d3" />


### Network Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                          VPC (10.0.0.0/16)                      │
│                                                                 │
│  ┌──────────────────────┐      ┌──────────────────────┐        │
│  │   Public Subnets     │      │  Private Subnets     │        │
│  │   (10.0.1.0/24)      │      │  (10.0.3.0/24)       │        │
│  │   (10.0.2.0/24)      │      │  (10.0.4.0/24)       │        │
│  │                      │      │                      │        │
│  │  ┌──────────────┐   │      │  ┌──────────────┐   │        │
│  │  │ NAT Gateway  │   │      │  │ EKS Nodes    │   │        │
│  │  │ (AZ-1)       │   │      │  │ (Workers)    │   │        │
│  │  └──────────────┘   │      │  │              │   │        │
│  │                     │      │  │  ┌────────┐  │   │        │
│  │  ┌──────────────┐   │      │  │  │ Pods   │  │   │        │
│  │  │ NAT Gateway  │   │      │  │  │ (Apps) │  │   │        │
│  │  │ (AZ-2)       │   │      │  │  └────────┘  │   │        │
│  │  └──────────────┘   │      │  └──────┬───────┘   │        │
│  │                     │      │         │           │        │
│  └──────────┬──────────┘      └─────────┼───────────┘        │
│             │                           │                     │
│             │                           ▼                     │
│             │                  ┌──────────────┐               │
│             │                  │ RDS Instance │               │
│             │                  │ (Private)    │               │
│             │                  └──────────────┘               │
│             │                                                  │
│  ┌──────────▼──────────┐                                      │
│  │ Internet Gateway    │                                      │
│  └─────────────────────┘                                      │
└─────────────────────────────────────────────────────────────────┘
```

### Microservices Architecture

#### Service Overview

| Service | Port | Endpoints | Replicas (Prod) | Database |
|---------|------|-----------|-----------------|----------|
| **Gateway** | 8072 | `/api/accounts/**`, `/api/cards/**`, `/api/loans/**` | 2+ | N/A |
| **Accounts** | 8080 | `/api/create`, `/api/fetch`, `/api/update`, `/api/delete` | 2+ | PostgreSQL |
| **Cards** | 9000 | `/api/create`, `/api/fetch`, `/api/update`, `/api/delete` | 2+ | PostgreSQL |
| **Loans** | 8090 | `/api/create`, `/api/fetch`, `/api/update`, `/api/delete` | 2+ | PostgreSQL |

#### Service Dependencies

```
Gateway Service
    ├── Accounts Service (http://accounts:8080)
    ├── Cards Service (http://cards:9000)
    └── Loans Service (http://loans:8090)

All Services
    └── RDS PostgreSQL (via IRSA + External Secrets)
```

### Infrastructure Components

#### Networking
- **VPC**: Custom VPC with public and private subnets across multiple AZs
- **NAT Gateway**: Multi-AZ NAT gateways for private subnet internet access
- **Internet Gateway**: Public internet access for public subnets
- **Security Groups**: Network-level security for EKS, RDS, and application services
- **Route Tables**: Custom routing for public and private subnets

#### Compute
- **EKS Cluster**: Managed Kubernetes cluster with control plane logging enabled
- **Node Groups**: Managed node groups with auto-scaling capabilities
- **Instance Types**: 
  - Dev: `t3.medium` (2 nodes)
  - Staging: `t3.large` (2-4 nodes)
  - Production: `t3.2xlarge` (4-6 nodes)

#### Database
- **RDS PostgreSQL**: Managed database with automated backups
- **Multi-AZ**: Enabled for production environments
- **Encryption**: Encryption at rest and in transit
- **Backup Retention**: 
  - Dev: 0 days (disabled)
  - Staging: 7 days
  - Production: 30 days

#### Container Registry
- **ECR**: Amazon Elastic Container Registry for Docker images
- **Repositories**: One repository per microservice (accounts, cards, loans, gateway)
- **Image Scanning**: Automated vulnerability scanning on push
- **Lifecycle Policies**: Automated cleanup of untagged images

#### Secrets Management
- **AWS Secrets Manager**: Centralized secret storage for database credentials
- **External Secrets Operator**: Kubernetes operator for secret synchronization
- **IRSA**: IAM Roles for Service Accounts for secure secret access
- **Secret Rotation**: Automated secret rotation (30-day intervals)

#### IAM & Access Control
- **IRSA**: IAM Roles for Service Accounts for pod-level AWS access
- **GitHub OIDC**: OIDC authentication for GitHub Actions CI/CD
- **Least Privilege**: Minimal IAM permissions for all roles
- **Role-Based Access**: Environment-specific IAM roles

### Environment Structure

#### Environments

| Environment | Purpose | Cluster Name | Node Type | RDS Instance | Multi-AZ |
|------------|---------|--------------|-----------|--------------|----------|
| **dev** | Development & Testing | `bankingapp-dev-eks` | t3.medium | db.t3.micro | No |
| **staging** | Pre-production Testing | `bankingapp-stag-eks` | t3.large | db.t3.small | No |
| **production** | Production Workloads | `bankingapp-prod-eks` | t3.2xlarge | db.m5.large | Yes |

#### Environment Isolation

- **Separate AWS Accounts**: Recommended for production (not implemented)
- **Separate VPCs**: One VPC per environment
- **Separate EKS Clusters**: One cluster per environment
- **Separate RDS Instances**: One database per environment
- **Separate ECR Repositories**: Environment-tagged images
- **Separate IAM Roles**: Environment-specific roles

### Technology Stack

#### Infrastructure
- **Terraform**: >= 1.6.0 (Infrastructure as Code)
- **AWS Provider**: ~> 5.0
- **Helm Provider**: ~> 2.7
- **Kubernetes Provider**: Latest

#### Container Orchestration
- **Kubernetes**: 1.28+ (EKS Managed)
- **Helm**: 3.12+ (Package Management)
- **External Secrets Operator**: 0.9.11

#### CI/CD
- **GitHub Actions**: Workflow automation
- **OIDC**: GitHub OIDC for AWS authentication
- **Trivy**: Container vulnerability scanning
- **Cosign**: Container image signing

#### Application
- **Spring Boot**: Latest (Microservices framework)
- **Java**: 21 (Temurin)
- **Spring Cloud Gateway**: API Gateway
- **PostgreSQL Driver**: Latest

#### Database
- **PostgreSQL**: 13.15+ (RDS Managed)
- **Connection Pooling**: HikariCP

#### Monitoring
- **Spring Boot Actuator**: Health checks and metrics
- **Prometheus**: Metrics endpoint (exposed)
- **CloudWatch**: AWS native monitoring (optional)

---

## Deployment Guide

### Prerequisites

#### Required Tools

| Tool | Version | Purpose |
|------|---------|---------|
| **Terraform** | >= 1.6.0 | Infrastructure provisioning |
| **kubectl** | >= 1.28 | Kubernetes cluster management |
| **Helm** | >= 3.12 | Kubernetes package management |
| **AWS CLI** | >= 2.0 | AWS service interaction |
| **Docker** | Latest | Container image building |
| **Git** | Latest | Version control |

#### AWS Account Requirements

- **AWS Account**: Active AWS account with appropriate permissions
- **IAM Permissions**: Administrator access or equivalent for initial setup
- **Region**: `us-east-1` (configurable)
- **Service Quotas**: Ensure sufficient quotas for EKS, RDS, ECR

#### GitHub Repository Setup

- **Repository**: GitHub repository with OIDC configured
- **Secrets**: AWS account ID, region, OIDC role ARN
- **Workflows**: GitHub Actions workflows enabled

#### Environment Variables

```bash
export AWS_ACCOUNT_ID="063630846340"
export AWS_REGION="us-east-1"
export CLUSTER_NAME="bankingapp-dev-eks"
export ENVIRONMENT="dev"
```

### Infrastructure Deployment (Terraform)

#### Step 1: Initial Setup

##### 1.1 Configure AWS Credentials

```bash
# Option 1: AWS CLI Configuration
aws configure

# Option 2: Environment Variables
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_DEFAULT_REGION="us-east-1"

# Option 3: AWS SSO
aws sso login --profile your-profile
```

##### 1.2 Set Up S3 Backend for Terraform State

```bash
# Create S3 bucket for Terraform state
aws s3 mb s3://banking-terraform-state-$(date +%s) --region us-east-1

# Enable versioning
aws s3api put-bucket-versioning \
    --bucket banking-terraform-state-$(date +%s) \
    --versioning-configuration Status=Enabled

# Enable encryption
aws s3api put-bucket-encryption \
    --bucket banking-terraform-state-$(date +%s) \
    --server-side-encryption-configuration '{
        "Rules": [{
            "ApplyServerSideEncryptionByDefault": {
                "SSEAlgorithm": "AES256"
            }
        }]
    }'
```

##### 1.3 Set Up DynamoDB for State Locking

```bash
# Create DynamoDB table for state locking
aws dynamodb create-table \
    --table-name terraform-locks \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST \
    --region us-east-1
```

##### 1.4 Configure Backend Configuration

Update `terraform/environments/dev/backend.tf`:

```hcl
terraform {
  backend "s3" {
    bucket         = "banking-terraform-state-18.10.25"
    key            = "envs/dev/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}
```

#### Step 2: Deploy Infrastructure

##### 2.1 Initialize Terraform

```bash
cd terraform/environments/dev
terraform init
```

##### 2.2 Review Terraform Plan

```bash
terraform plan -var-file=dev.tfvars
```

##### 2.3 Apply Terraform Configuration

```bash
terraform apply -var-file=dev.tfvars
```

**Expected Output:**
```
Apply complete! Resources: 25 added, 0 changed, 0 destroyed.

Outputs:

cluster_name = "bankingapp-dev-eks"
cluster_endpoint = "https://xxxxx.gr7.us-east-1.eks.amazonaws.com"
ecr_repository_urls = {
  "accounts" = "063630846340.dkr.ecr.us-east-1.amazonaws.com/accounts"
  "cards" = "063630846340.dkr.ecr.us-east-1.amazonaws.com/cards"
  "loans" = "063630846340.dkr.ecr.us-east-1.amazonaws.com/loans"
  "gateway" = "063630846340.dkr.ecr.us-east-1.amazonaws.com/gateway"
}
```

##### 2.4 Post-Deployment Validation

```bash
# Verify EKS cluster
aws eks describe-cluster --name bankingapp-dev-eks --region us-east-1

# Verify RDS instance
aws rds describe-db-instances --db-instance-identifier dev-db --region us-east-1

# Verify ECR repositories
aws ecr describe-repositories --region us-east-1
```

#### Step 3: Configure kubectl

```bash
# Update kubeconfig
aws eks update-kubeconfig --name bankingapp-dev-eks --region us-east-1

# Verify cluster access
kubectl cluster-info
kubectl get nodes
```

### Application Deployment (Helm)

#### Step 1: Pre-deployment Setup

##### 1.1 Install External Secrets Operator

```bash
# Add Helm repository
helm repo add external-secrets https://charts.external-secrets.io
helm repo update

# Install External Secrets Operator
helm install external-secrets external-secrets/external-secrets \
    --namespace external-secrets \
    --create-namespace \
    --version 0.9.11
```

##### 1.2 Verify External Secrets Operator

```bash
kubectl get pods -n external-secrets
kubectl get crd | grep externalsecrets
```

##### 1.3 Set Up SecretStore

The SecretStore is already configured in Helm charts. Verify it exists:

```bash
kubectl get secretstore -n default
kubectl describe secretstore aws-secret-store -n default
```

##### 1.4 Verify Service Accounts and IRSA Roles

```bash
# Check service accounts
kubectl get serviceaccounts -n default

# Verify IRSA annotations
kubectl get serviceaccount accounts-sa -n default -o yaml
kubectl get serviceaccount cards-sa -n default -o yaml
kubectl get serviceaccount loans-sa -n default -o yaml
```

#### Step 2: Build and Push Docker Images

##### 2.1 Build Docker Images

```bash
# Build accounts service
cd accounts
docker build -t 063630846340.dkr.ecr.us-east-1.amazonaws.com/accounts:latest .

# Build cards service
cd ../cards
docker build -t 063630846340.dkr.ecr.us-east-1.amazonaws.com/cards:latest .

# Build loans service
cd ../loans
docker build -t 063630846340.dkr.ecr.us-east-1.amazonaws.com/loans:latest .

# Build gateway service
cd ../gatewayserver
docker build -t 063630846340.dkr.ecr.us-east-1.amazonaws.com/gateway:latest .
```

##### 2.2 Push to ECR

```bash
# Login to ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 063630846340.dkr.ecr.us-east-1.amazonaws.com

# Push images
docker push 063630846340.dkr.ecr.us-east-1.amazonaws.com/accounts:latest
docker push 063630846340.dkr.ecr.us-east-1.amazonaws.com/cards:latest
docker push 063630846340.dkr.ecr.us-east-1.amazonaws.com/loans:latest
docker push 063630846340.dkr.ecr.us-east-1.amazonaws.com/gateway:latest
```

#### Step 3: Deploy Helm Charts

##### 3.1 Package Helm Charts

```bash
# Package service charts
cd helm/bankingapp-services
helm package accounts
helm package cards
helm package loans
helm package gateway

# Package common chart
cd ../bankingapp-common
helm package .
```

##### 3.2 Deploy to Development Environment

```bash
# Navigate to environment directory
cd ../environments/dev-env

# Install/Upgrade Helm release
helm upgrade --install banking-app . \
    --namespace default \
    --create-namespace \
    --values values.yaml \
    --wait \
    --timeout 10m
```

##### 3.3 Verify Deployment

```bash
# Check pods
kubectl get pods -n default

# Check services
kubectl get svc -n default

# Check external secrets
kubectl get externalsecret -n default
kubectl get secrets -n default

# Check deployments
kubectl get deployments -n default
```

#### Step 4: Post-deployment Validation

##### 4.1 Verify Pods are Running

```bash
kubectl get pods -n default
```

**Expected Output:**
```
NAME                              READY   STATUS    RESTARTS   AGE
accounts-deployment-xxx           1/1     Running   0          5m
cards-deployment-xxx              1/1     Running   0          5m
loans-deployment-xxx              1/1     Running   0          5m
gateway-deployment-xxx            1/1     Running   0          5m
```

##### 4.2 Check Service Endpoints

```bash
kubectl get svc -n default
```

**Expected Output:**
```
NAME         TYPE           CLUSTER-IP      EXTERNAL-IP      PORT(S)          AGE
accounts     ClusterIP      10.100.x.x      <none>           8080/TCP         5m
cards        ClusterIP      10.100.x.x      <none>           9000/TCP         5m
loans        ClusterIP      10.100.x.x      <none>           8090/TCP         5m
gateway      LoadBalancer   10.100.x.x      xxxxx.elb.amazonaws.com   8072:30000/TCP   5m
```

##### 4.3 Test Health Endpoints

```bash
# Test gateway health
curl http://$(kubectl get svc gateway -n default -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'):8072/actuator/health

# Test accounts health
kubectl port-forward svc/accounts 8080:8080 -n default
curl http://localhost:8080/actuator/health
```

##### 4.4 Verify Database Connectivity

```bash
# Check pod logs for database connection
kubectl logs -f deployment/accounts-deployment -n default
kubectl logs -f deployment/cards-deployment -n default
kubectl logs -f deployment/loans-deployment -n default
```

##### 4.5 Test API Endpoints

```bash
# Get gateway external IP
GATEWAY_IP=$(kubectl get svc gateway -n default -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

# Test accounts API
curl -X GET http://${GATEWAY_IP}:8072/api/accounts/fetch?mobileNumber=1234567890

# Test cards API
curl -X GET http://${GATEWAY_IP}:8072/api/cards/fetch?mobileNumber=1234567890

# Test loans API
curl -X GET http://${GATEWAY_IP}:8072/api/loans/fetch?mobileNumber=1234567890
```

### CI/CD Deployment

#### GitHub Actions Workflow

The CI/CD pipeline is automated through GitHub Actions:

1. **Code Push**: Triggered on push to `main` or `develop` branches
2. **Build**: Docker images are built and pushed to ECR
3. **Scan**: Trivy scans images for vulnerabilities
4. **Sign**: Cosign signs images for verification
5. **Deploy**: Helm charts are deployed to EKS (optional)

#### Manual Deployment via CI/CD

```bash
# Trigger workflow manually
gh workflow run gateway.yaml

# Check workflow status
gh run list --workflow=gateway.yaml
```

### Rollback Procedures

#### Helm Rollback

```bash
# List release history
helm history banking-app -n default

# Rollback to previous revision
helm rollback banking-app -n default

# Rollback to specific revision
helm rollback banking-app <revision-number> -n default
```

#### Terraform Rollback

```bash
# Rollback specific module
terraform apply -var-file=dev.tfvars -target=module.rds

# Rollback entire infrastructure
terraform destroy -var-file=dev.tfvars
terraform apply -var-file=dev.tfvars
```

#### Database Rollback

See [Database Backup and Restore Runbook](docs/runbooks/database-backup-restore.md) for detailed procedures.

---

## Troubleshooting

### Common Issues and Solutions

#### Pod Issues

##### Pods Not Starting

**Symptoms:**
- Pods stuck in `Pending` state
- Pods in `ImagePullBackOff` state
- Pods in `ErrImagePull` state

**Diagnosis:**
```bash
# Check pod status
kubectl get pods -n default
kubectl describe pod <pod-name> -n default

# Check pod events
kubectl get events -n default --sort-by='.lastTimestamp'
```

**Solutions:**

1. **Image Pull Errors:**
```bash
# Verify ECR repository exists
aws ecr describe-repositories --region us-east-1

# Check image exists
aws ecr describe-images --repository-name accounts --region us-east-1

# Verify node IAM role has ECR permissions
aws iam get-role-policy --role-name <node-role> --policy-name <policy-name>
```

2. **Resource Constraints:**
```bash
# Check node resources
kubectl describe nodes

# Check pod resource requests
kubectl describe pod <pod-name> -n default | grep -A 5 "Requests:"

# Scale nodes if needed
aws eks update-nodegroup-config \
    --cluster-name bankingapp-dev-eks \
    --nodegroup-name <nodegroup-name> \
    --scaling-config minSize=2,maxSize=4,desiredSize=3
```

3. **Secrets Not Found:**
```bash
# Check external secrets
kubectl get externalsecret -n default
kubectl describe externalsecret <secret-name> -n default

# Check secrets
kubectl get secrets -n default
kubectl describe secret <secret-name> -n default

# Check service account annotations
kubectl get serviceaccount accounts-sa -n default -o yaml
```

##### Pods Crashing

**Symptoms:**
- Pods in `CrashLoopBackOff` state
- Pods restarting continuously
- Application errors in logs

**Diagnosis:**
```bash
# Check pod logs
kubectl logs <pod-name> -n default
kubectl logs <pod-name> -n default --previous

# Check pod events
kubectl describe pod <pod-name> -n default
```

**Solutions:**

1. **Database Connection Issues:**
```bash
# Verify database endpoint
kubectl get secret dev-db-credentials -n default -o jsonpath='{.data.HOST}' | base64 -d

# Test database connectivity from pod
kubectl exec -it <pod-name> -n default -- sh
# Inside pod:
# telnet <db-host> 5432
# psql -h <db-host> -U <db-user> -d <db-name>
```

2. **Health Probe Failures:**
```bash
# Check health endpoint
kubectl exec -it <pod-name> -n default -- wget -qO- http://localhost:8080/actuator/health

# Verify health probe configuration
kubectl get deployment accounts-deployment -n default -o yaml | grep -A 10 "livenessProbe"
```

3. **Memory/CPU Limits:**
```bash
# Check resource usage
kubectl top pod <pod-name> -n default

# Adjust resource limits in Helm values
# helm/bankingapp-services/accounts/values.yaml
resources:
  requests:
    memory: "256Mi"
    cpu: "100m"
  limits:
    memory: "512Mi"
    cpu: "500m"
```

#### Network Issues

##### Service Connectivity

**Symptoms:**
- Services cannot communicate with each other
- Gateway cannot reach microservices
- Database connection timeouts

**Diagnosis:**
```bash
# Check service endpoints
kubectl get endpoints -n default
kubectl describe svc accounts -n default

# Test service DNS
kubectl run -it --rm debug --image=busybox --restart=Never -- nslookup accounts
kubectl run -it --rm debug --image=busybox --restart=Never -- wget -qO- http://accounts:8080/actuator/health
```

**Solutions:**

1. **Service DNS Issues:**
```bash
# Verify service exists
kubectl get svc accounts -n default

# Check service selector matches pod labels
kubectl get svc accounts -n default -o yaml | grep selector
kubectl get pods -n default --show-labels
```

2. **Network Policy Issues:**
```bash
# Check network policies
kubectl get networkpolicies -n default
kubectl describe networkpolicy <policy-name> -n default

# Temporarily disable network policies for testing
kubectl delete networkpolicy <policy-name> -n default
```

3. **Security Group Issues:**
```bash
# Verify security group rules
aws ec2 describe-security-groups --group-ids <sg-id> --region us-east-1

# Check RDS security group allows EKS nodes
aws ec2 describe-security-groups --filters "Name=group-name,Values=dev-rds-sg" --region us-east-1
```

##### Gateway Routing

**Symptoms:**
- Gateway returns 404 for valid routes
- Gateway cannot reach backend services
- CORS errors

**Diagnosis:**
```bash
# Check gateway logs
kubectl logs -f deployment/gateway-deployment -n default

# Test gateway routes
curl -v http://<gateway-ip>:8072/api/accounts/fetch?mobileNumber=1234567890
```

**Solutions:**

1. **Route Configuration:**
```bash
# Verify gateway configuration
kubectl get configmap bankingapp-config -n default -o yaml

# Check gateway routes
kubectl exec -it deployment/gateway-deployment -n default -- cat /app/application.yml
```

2. **Service Discovery:**
```bash
# Verify service DNS resolution
kubectl exec -it deployment/gateway-deployment -n default -- nslookup accounts
kubectl exec -it deployment/gateway-deployment -n default -- wget -qO- http://accounts:8080/actuator/health
```

#### Database Issues

##### Connection Failures

**Symptoms:**
- Database connection timeouts
- Authentication failures
- Connection pool exhaustion

**Diagnosis:**
```bash
# Check database endpoint
aws rds describe-db-instances --db-instance-identifier dev-db --region us-east-1

# Test database connectivity
kubectl run -it --rm psql --image=postgres:13 --restart=Never -- psql -h <db-endpoint> -U <db-user> -d <db-name>
```

**Solutions:**

1. **Security Group Configuration:**
```bash
# Verify security group allows EKS nodes
aws ec2 describe-security-groups --filters "Name=group-name,Values=dev-rds-sg" --region us-east-1

# Add security group rule if needed
aws ec2 authorize-security-group-ingress \
    --group-id <sg-id> \
    --protocol tcp \
    --port 5432 \
    --source-group <eks-node-sg-id> \
    --region us-east-1
```

2. **Credentials Issues:**
```bash
# Verify secrets are synced
kubectl get secret dev-db-credentials -n default -o yaml

# Check external secrets status
kubectl get externalsecret dev-db-credentials -n default -o yaml
kubectl describe externalsecret dev-db-credentials -n default
```

3. **Connection Pool Configuration:**
```yaml
# Update application.yml
spring:
  datasource:
    hikari:
      maximum-pool-size: 10
      minimum-idle: 5
      connection-timeout: 30000
```

##### Performance Issues

**Symptoms:**
- Slow query performance
- High database CPU usage
- Connection pool exhaustion

**Diagnosis:**
```bash
# Check database metrics
aws cloudwatch get-metric-statistics \
    --namespace AWS/RDS \
    --metric-name CPUUtilization \
    --dimensions Name=DBInstanceIdentifier,Value=dev-db \
    --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
    --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
    --period 300 \
    --statistics Average \
    --region us-east-1
```

**Solutions:**

1. **Query Optimization:**
```sql
-- Check slow queries
SELECT * FROM pg_stat_statements ORDER BY total_time DESC LIMIT 10;

-- Analyze tables
ANALYZE accounts;
ANALYZE cards;
ANALYZE loans;
```

2. **Connection Pool Tuning:**
```yaml
# Increase connection pool size
spring:
  datasource:
    hikari:
      maximum-pool-size: 20
      minimum-idle: 10
```

3. **Database Scaling:**
```bash
# Scale RDS instance
aws rds modify-db-instance \
    --db-instance-identifier dev-db \
    --db-instance-class db.t3.small \
    --apply-immediately \
    --region us-east-1
```

#### Secret Management Issues

##### External Secrets Not Syncing

**Symptoms:**
- Secrets not appearing in Kubernetes
- Pods cannot access secrets
- External secrets in error state

**Diagnosis:**
```bash
# Check external secrets operator
kubectl get pods -n external-secrets
kubectl logs -f deployment/external-secrets -n external-secrets

# Check external secrets
kubectl get externalsecret -n default
kubectl describe externalsecret dev-db-credentials -n default
```

**Solutions:**

1. **IRSA Role Issues:**
```bash
# Verify service account annotations
kubectl get serviceaccount external-secrets-sa -n external-secrets -o yaml

# Check IAM role permissions
aws iam get-role-policy --role-name dev-external-secrets-role --policy-name dev-external-secrets-policy
```

2. **SecretStore Configuration:**
```bash
# Verify SecretStore
kubectl get secretstore aws-secret-store -n default -o yaml
kubectl describe secretstore aws-secret-store -n default
```

3. **AWS Secrets Manager:**
```bash
# Verify secret exists in AWS
aws secretsmanager describe-secret --secret-id dev-db-credentials --region us-east-1

# Check secret value
aws secretsmanager get-secret-value --secret-id dev-db-credentials --region us-east-1
```

### Debugging Commands

#### Kubernetes Commands

```bash
# Get pod logs
kubectl logs <pod-name> -n default
kubectl logs <pod-name> -n default --previous
kubectl logs -f deployment/<deployment-name> -n default

# Describe resources
kubectl describe pod <pod-name> -n default
kubectl describe svc <service-name> -n default
kubectl describe deployment <deployment-name> -n default

# Execute commands in pod
kubectl exec -it <pod-name> -n default -- sh
kubectl exec -it <pod-name> -n default -- /bin/bash

# Get resource information
kubectl get pods -n default -o wide
kubectl get svc -n default -o wide
kubectl get deployments -n default -o wide
kubectl get events -n default --sort-by='.lastTimestamp'
```

#### Terraform Commands

```bash
# List resources
terraform state list

# Show resource details
terraform show
terraform state show <resource-address>

# Refresh state
terraform refresh -var-file=dev.tfvars

# Validate configuration
terraform validate

# Format configuration
terraform fmt -recursive
```

#### AWS Commands

```bash
# EKS cluster information
aws eks describe-cluster --name bankingapp-dev-eks --region us-east-1
aws eks list-nodegroups --cluster-name bankingapp-dev-eks --region us-east-1

# RDS instance information
aws rds describe-db-instances --db-instance-identifier dev-db --region us-east-1
aws rds describe-db-snapshots --db-instance-identifier dev-db --region us-east-1

# ECR repository information
aws ecr describe-repositories --region us-east-1
aws ecr describe-images --repository-name accounts --region us-east-1
```

#### Database Commands

```bash
# Connect to database
kubectl run -it --rm psql --image=postgres:13 --restart=Never -- psql -h <db-endpoint> -U <db-user> -d <db-name>

# Check database connections
SELECT * FROM pg_stat_activity;

# Check database size
SELECT pg_database.datname, pg_size_pretty(pg_database_size(pg_database.datname)) AS size FROM pg_database;
```

### Logging and Monitoring

#### Accessing Application Logs

```bash
# Stream pod logs
kubectl logs -f deployment/accounts-deployment -n default
kubectl logs -f deployment/cards-deployment -n default
kubectl logs -f deployment/loans-deployment -n default
kubectl logs -f deployment/gateway-deployment -n default

# Get logs from all pods in deployment
kubectl logs -f deployment/accounts-deployment -n default --all-containers=true

# Get logs from specific container
kubectl logs -f deployment/accounts-deployment -n default -c accounts
```

#### Viewing Cluster Logs

```bash
# EKS control plane logs (if enabled)
aws logs describe-log-groups --log-group-name-prefix /aws/eks/bankingapp-dev-eks --region us-east-1
aws logs tail /aws/eks/bankingapp-dev-eks/cluster --follow --region us-east-1

# CloudWatch Logs
aws logs describe-log-groups --region us-east-1
aws logs tail <log-group-name> --follow --region us-east-1
```

#### Monitoring Metrics

```bash
# Prometheus metrics endpoint
kubectl port-forward svc/accounts 8080:8080 -n default
curl http://localhost:8080/actuator/prometheus

# CloudWatch metrics
aws cloudwatch get-metric-statistics \
    --namespace AWS/EKS \
    --metric-name CPUUtilization \
    --dimensions Name=ClusterName,Value=bankingapp-dev-eks \
    --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
    --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
    --period 300 \
    --statistics Average \
    --region us-east-1
```

### Performance Troubleshooting

#### High Latency

**Diagnosis:**
```bash
# Check pod resource usage
kubectl top pods -n default

# Check node resource usage
kubectl top nodes

# Check database query performance
kubectl exec -it deployment/accounts-deployment -n default -- psql -h <db-endpoint> -U <db-user> -d <db-name> -c "SELECT * FROM pg_stat_statements ORDER BY total_time DESC LIMIT 10;"
```

**Solutions:**

1. **Database Query Optimization:**
```sql
-- Create indexes
CREATE INDEX idx_accounts_mobile_number ON accounts(mobile_number);
CREATE INDEX idx_cards_mobile_number ON cards(mobile_number);
CREATE INDEX idx_loans_mobile_number ON loans(mobile_number);
```

2. **Connection Pool Tuning:**
```yaml
# Increase connection pool size
spring:
  datasource:
    hikari:
      maximum-pool-size: 20
      minimum-idle: 10
      connection-timeout: 30000
```

3. **Resource Scaling:**
```bash
# Scale deployment
kubectl scale deployment accounts-deployment --replicas=3 -n default

# Scale node group
aws eks update-nodegroup-config \
    --cluster-name bankingapp-dev-eks \
    --nodegroup-name <nodegroup-name> \
    --scaling-config minSize=2,maxSize=4,desiredSize=3
```

#### High CPU/Memory Usage

**Diagnosis:**
```bash
# Check pod resource usage
kubectl top pods -n default

# Check resource limits
kubectl describe pod <pod-name> -n default | grep -A 5 "Limits:"
```

**Solutions:**

1. **Adjust Resource Limits:**
```yaml
# Update Helm values
resources:
  requests:
    memory: "512Mi"
    cpu: "200m"
  limits:
    memory: "1Gi"
    cpu: "1000m"
```

2. **Horizontal Pod Autoscaling:**
```yaml
# Enable HPA
autoscaling:
  enabled: true
  minReplicas: 2
  maxReplicas: 10
  targetCPUUtilizationPercentage: 70
```

---

## Security Best Practices

### Infrastructure Security

#### Network Security

- **Private Subnets**: All application pods run in private subnets
- **Security Groups**: Least privilege security group rules
- **Network Policies**: Kubernetes network policies for pod-to-pod communication
- **VPC Flow Logs**: Enable VPC flow logs for network traffic monitoring

#### VPC Security

```hcl
# Enable VPC flow logs
resource "aws_flow_log" "main" {
  iam_role_arn    = aws_iam_role.flow_log.arn
  log_destination = aws_cloudwatch_log_group.vpc_flow_log.arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.main.id
}
```

#### EKS Security

- **Control Plane Logging**: Enable all control plane log types
- **Node Security Groups**: Dedicated security groups for worker nodes
- **Pod Security Policies**: Implement pod security policies (deprecated, use Pod Security Standards)
- **Network Policies**: Restrict pod-to-pod communication

#### RDS Security

- **Encryption at Rest**: Enable encryption for RDS instances
- **Encryption in Transit**: Use SSL/TLS for database connections
- **Network Isolation**: RDS in private subnets with security groups
- **Multi-AZ**: Enable multi-AZ for production environments
- **Automated Backups**: Enable automated backups with encryption

### Access Control

#### IAM Roles

- **Least Privilege**: Minimal IAM permissions for all roles
- **IRSA**: IAM Roles for Service Accounts for pod-level access
- **Role Separation**: Separate roles for different services and environments

#### Service Accounts

```yaml
# Service account with IRSA annotation
apiVersion: v1
kind: ServiceAccount
metadata:
  name: accounts-sa
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::ACCOUNT_ID:role/dev-accounts-rds-access-role
```

#### GitHub Actions

- **OIDC Authentication**: Use OIDC instead of static credentials
- **Role-Based Access**: Environment-specific IAM roles
- **Least Privilege**: Minimal permissions for CI/CD workflows

#### Database Access

- **IAM Authentication**: Use IAM database authentication (optional)
- **Connection Encryption**: Enforce SSL/TLS for database connections
- **Network Isolation**: Restrict database access to EKS nodes only

### Secrets Management

#### AWS Secrets Manager

- **Centralized Storage**: All secrets stored in AWS Secrets Manager
- **Encryption**: Secrets encrypted at rest with KMS
- **Rotation**: Automated secret rotation (30-day intervals)
- **Versioning**: Secret versioning for audit and rollback

#### External Secrets Operator

- **Kubernetes Integration**: Sync secrets from AWS Secrets Manager to Kubernetes
- **IRSA**: Use IRSA for secure secret access
- **Automatic Sync**: Automatic secret synchronization and updates

#### Secret Rotation

```bash
# Enable secret rotation
aws secretsmanager rotate-secret --secret-id dev-db-credentials --region us-east-1
```

### Container Security

#### Image Scanning

- **Trivy Scanning**: Scan images for vulnerabilities in CI/CD
- **ECR Scanning**: Enable ECR image scanning on push
- **Automated Scanning**: Automated scanning in GitHub Actions workflows

#### Image Signing

- **Cosign Signing**: Sign images with Cosign for verification
- **Signature Verification**: Verify image signatures before deployment
- **Keyless Signing**: Use keyless signing with OIDC

#### Container Hardening

- **Minimal Base Images**: Use minimal base images (Alpine Linux)
- **Non-Root Users**: Run containers as non-root users
- **Read-Only Root Filesystem**: Use read-only root filesystem where possible
- **Resource Limits**: Set resource limits for all containers

### Application Security

#### API Security

- **Authentication**: Implement authentication for API endpoints
- **Authorization**: Role-based access control (RBAC)
- **Rate Limiting**: Implement rate limiting to prevent abuse
- **Input Validation**: Validate all input parameters

#### CORS Configuration

```yaml
# Production CORS configuration
globalcors:
  corsConfigurations:
    '[/**]':
      allowedOrigins: 
        - "https://yourdomain.com"
      allowedMethods:
        - GET
        - POST
        - PUT
        - DELETE
      allowedHeaders:
        - "Content-Type"
        - "Authorization"
```

#### Input Validation

- **Request Validation**: Validate all request parameters
- **SQL Injection Prevention**: Use parameterized queries
- **XSS Prevention**: Sanitize user input
- **CSRF Protection**: Implement CSRF protection

#### HTTPS/TLS

- **TLS Certificates**: Use TLS certificates for all external endpoints
- **Certificate Management**: Use AWS Certificate Manager (ACM) for certificates
- **TLS Version**: Enforce TLS 1.2 or higher

### Compliance and Auditing

#### Audit Logging

- **CloudTrail**: Enable CloudTrail for AWS API logging
- **EKS Audit Logs**: Enable EKS control plane audit logs
- **Application Logs**: Centralized application logging
- **Database Logs**: Enable RDS audit logs

#### Compliance

- **SOC 2**: Implement SOC 2 compliance controls
- **PCI DSS**: Implement PCI DSS compliance for payment processing
- **GDPR**: Implement GDPR compliance for data protection
- **HIPAA**: Implement HIPAA compliance for healthcare data (if applicable)

#### Security Scanning

- **Regular Audits**: Conduct regular security audits
- **Penetration Testing**: Perform penetration testing
- **Vulnerability Scanning**: Regular vulnerability scanning
- **Dependency Scanning**: Scan dependencies for vulnerabilities

#### Incident Response

See [Security Incident Response Runbook](docs/runbooks/security-incident-response.md) for detailed procedures.

---

## Cost Optimization

### Infrastructure Cost Optimization

#### EKS Costs

- **Node Instance Types**: Use appropriate instance types for workloads
- **Cluster Autoscaling**: Enable cluster autoscaling to scale nodes based on demand
- **Spot Instances**: Use spot instances for non-critical workloads
- **Right-Sizing**: Right-size node instances based on actual usage

**Cost Savings:**
- Use `t3.medium` for dev (vs `t3.large`)
- Use spot instances for dev/staging (up to 70% savings)
- Enable cluster autoscaling to reduce idle nodes

#### RDS Costs

- **Instance Sizing**: Right-size RDS instances based on actual usage
- **Storage Optimization**: Optimize storage allocation and usage
- **Backup Retention**: Adjust backup retention based on requirements
- **Multi-AZ**: Use multi-AZ only for production

**Cost Savings:**
- Use `db.t3.micro` for dev (vs `db.t3.small`)
- Reduce backup retention for dev (0 days vs 7 days)
- Use single-AZ for dev/staging (50% savings)

#### Network Costs

- **NAT Gateway**: Use single NAT gateway for dev/staging
- **Data Transfer**: Optimize data transfer between services
- **VPC Endpoints**: Use VPC endpoints to reduce data transfer costs

**Cost Savings:**
- Use single NAT gateway for dev/staging (50% savings)
- Use VPC endpoints for AWS services (reduce data transfer costs)

#### Storage Costs

- **ECR Storage**: Implement ECR lifecycle policies to clean up old images
- **EBS Volumes**: Use appropriate EBS volume types and sizes
- **S3 Storage**: Use appropriate S3 storage classes

**Cost Savings:**
- ECR lifecycle policies: Clean up untagged images after 7 days
- Use GP3 volumes instead of GP2 (20% cheaper)

### Resource Optimization

#### Container Resources

- **Right-Sizing**: Set appropriate resource requests and limits
- **Resource Monitoring**: Monitor resource usage and adjust accordingly
- **Over-Provisioning**: Avoid over-provisioning resources

**Optimization:**
```yaml
# Before (over-provisioned)
resources:
  requests:
    memory: "1Gi"
    cpu: "1000m"
  limits:
    memory: "2Gi"
    cpu: "2000m"

# After (right-sized)
resources:
  requests:
    memory: "256Mi"
    cpu: "100m"
  limits:
    memory: "512Mi"
    cpu: "500m"
```

#### Auto-Scaling

- **Horizontal Pod Autoscaling**: Enable HPA for automatic pod scaling
- **Cluster Autoscaling**: Enable cluster autoscaling for node scaling
- **Vertical Pod Autoscaling**: Use VPA for resource optimization (optional)

**Cost Savings:**
- HPA: Scale down during low traffic (reduce resource usage)
- Cluster Autoscaling: Scale down nodes during low demand (reduce costs)

#### Resource Quotas

- **Namespace Quotas**: Set resource quotas per namespace
- **Limit Ranges**: Set limit ranges for containers
- **Resource Monitoring**: Monitor resource usage and adjust quotas

### Cost Monitoring

#### AWS Cost Explorer

- **Cost Analysis**: Analyze costs by service, environment, and resource
- **Cost Trends**: Monitor cost trends over time
- **Cost Forecasting**: Forecast future costs based on trends

#### Budget Alerts

```bash
# Create budget alert
aws budgets create-budget \
    --account-id ACCOUNT_ID \
    --budget file://budget.json \
    --notifications-with-subscribers file://notifications.json
```

#### Cost Allocation Tags

- **Resource Tagging**: Tag all resources with cost allocation tags
- **Tag Strategy**: Use consistent tagging strategy across all resources
- **Cost Reporting**: Generate cost reports by tags

**Tagging Strategy:**
```hcl
tags = {
  Environment = var.environment
  Project     = "banking-app"
  ManagedBy   = "Terraform"
  CostCenter  = "engineering"
}
```

#### Cost Optimization Recommendations

- **AWS Trusted Advisor**: Use Trusted Advisor for cost optimization recommendations
- **Cost Explorer**: Use Cost Explorer for cost analysis and optimization
- **Reserved Instances**: Consider reserved instances for predictable workloads

### Environment-Specific Optimization

#### Development

- **Smaller Instances**: Use smaller instance types (t3.medium)
- **Single-AZ**: Use single-AZ deployment
- **Reduced Backups**: Disable backups or use minimal retention
- **Spot Instances**: Use spot instances for cost savings

**Estimated Cost:**
- EKS: ~$50/month
- RDS: ~$15/month
- NAT Gateway: ~$32/month
- **Total: ~$100/month**

#### Staging

- **Medium Instances**: Use medium instance types (t3.large)
- **Single-AZ**: Use single-AZ deployment
- **Minimal Backups**: Use minimal backup retention (7 days)
- **On-Demand Instances**: Use on-demand instances for stability

**Estimated Cost:**
- EKS: ~$150/month
- RDS: ~$30/month
- NAT Gateway: ~$32/month
- **Total: ~$220/month**

#### Production

- **Right-Sized Instances**: Use right-sized instance types (t3.2xlarge)
- **Multi-AZ**: Use multi-AZ deployment for high availability
- **Extended Backups**: Use extended backup retention (30 days)
- **On-Demand Instances**: Use on-demand instances for reliability

**Estimated Cost:**
- EKS: ~$600/month
- RDS: ~$200/month
- NAT Gateway: ~$64/month (multi-AZ)
- **Total: ~$900/month**

### Cost Reduction Strategies

#### Reserved Instances

- **RDS Reserved Instances**: Purchase reserved instances for RDS (up to 40% savings)
- **EC2 Reserved Instances**: Purchase reserved instances for EC2 (up to 40% savings)
- **Savings Plans**: Use savings plans for flexible cost savings

#### Spot Instances

- **EKS Spot Instances**: Use spot instances for non-critical workloads (up to 70% savings)
- **Spot Fleet**: Use spot fleet for automatic spot instance management
- **Fallback Strategy**: Implement fallback to on-demand instances

#### Storage Optimization

- **ECR Lifecycle Policies**: Clean up old images automatically
- **RDS Storage Optimization**: Optimize RDS storage allocation
- **S3 Storage Classes**: Use appropriate S3 storage classes

#### Network Optimization

- **VPC Endpoints**: Use VPC endpoints to reduce data transfer costs
- **CloudFront**: Use CloudFront for content delivery (reduce data transfer costs)
- **Data Transfer Optimization**: Optimize data transfer between services

---

## Disaster Recovery

### Disaster Recovery Strategy

#### Recovery Time Objective (RTO)

- **Development**: 24 hours
- **Staging**: 12 hours
- **Production**: 1 hour

#### Recovery Point Objective (RPO)

- **Development**: 24 hours
- **Staging**: 6 hours
- **Production**: 15 minutes

#### Backup Strategy

- **Automated Backups**: Daily automated backups for all environments
- **Manual Snapshots**: Manual snapshots before major changes
- **Backup Retention**: 
  - Dev: 0 days (disabled)
  - Staging: 7 days
  - Production: 30 days

#### Recovery Procedures

See [Disaster Recovery Runbook](docs/runbooks/disaster-recovery.md) for detailed procedures.

### Backup Procedures

#### Database Backups

##### Automated Backups

- **RDS Automated Backups**: Enabled for all environments (except dev)
- **Backup Window**: Configured during low-traffic hours
- **Backup Retention**: Environment-specific retention periods

##### Manual Snapshots

```bash
# Create manual snapshot
aws rds create-db-snapshot \
    --db-instance-identifier dev-db \
    --db-snapshot-identifier dev-db-snapshot-$(date +%Y%m%d) \
    --region us-east-1

# List snapshots
aws rds describe-db-snapshots \
    --db-instance-identifier dev-db \
    --region us-east-1
```

##### Backup Verification

```bash
# Verify backup exists
aws rds describe-db-snapshots \
    --db-snapshot-identifier dev-db-snapshot-20240101 \
    --region us-east-1

# Test backup restoration (to new instance)
aws rds restore-db-instance-from-db-snapshot \
    --db-instance-identifier dev-db-restore \
    --db-snapshot-identifier dev-db-snapshot-20240101 \
    --region us-east-1
```

#### Application Backups

##### ConfigMaps and Secrets

```bash
# Backup ConfigMaps
kubectl get configmap -n default -o yaml > configmaps-backup.yaml

# Backup Secrets
kubectl get secrets -n default -o yaml > secrets-backup.yaml

# Backup External Secrets
kubectl get externalsecret -n default -o yaml > externalsecrets-backup.yaml
```

##### Helm Releases

```bash
# Backup Helm release
helm get values banking-app -n default > helm-values-backup.yaml
helm get manifest banking-app -n default > helm-manifest-backup.yaml
```

#### Infrastructure Backups

##### Terraform State

- **S3 Backend**: Terraform state stored in S3 with versioning
- **State Locking**: DynamoDB table for state locking
- **State Backup**: S3 versioning provides automatic backup

##### Helm Charts

```bash
# Backup Helm charts
tar -czf helm-charts-backup.tar.gz helm/

# Backup to S3
aws s3 cp helm-charts-backup.tar.gz s3://backup-bucket/helm-charts-backup.tar.gz
```

### Recovery Procedures

#### Database Recovery

##### Point-in-Time Recovery

```bash
# Restore to point in time
aws rds restore-db-instance-to-point-in-time \
    --source-db-instance-identifier dev-db \
    --target-db-instance-identifier dev-db-restore \
    --restore-time 2024-01-01T12:00:00Z \
    --region us-east-1
```

##### Snapshot Restoration

```bash
# Restore from snapshot
aws rds restore-db-instance-from-db-snapshot \
    --db-instance-identifier dev-db-restore \
    --db-snapshot-identifier dev-db-snapshot-20240101 \
    --region us-east-1

# Update application configuration
kubectl set env deployment/accounts-deployment DB_HOST=<new-db-endpoint> -n default
```

#### Application Recovery

##### Helm Rollback

```bash
# Rollback to previous revision
helm rollback banking-app -n default

# Rollback to specific revision
helm rollback banking-app <revision-number> -n default
```

##### Pod Restart

```bash
# Restart deployment
kubectl rollout restart deployment/accounts-deployment -n default

# Scale down and up
kubectl scale deployment accounts-deployment --replicas=0 -n default
kubectl scale deployment accounts-deployment --replicas=2 -n default
```

##### Service Restoration

```bash
# Restore service
kubectl apply -f service-backup.yaml

# Verify service
kubectl get svc accounts -n default
kubectl get endpoints accounts -n default
```

#### Infrastructure Recovery

##### Terraform Apply

```bash
# Restore infrastructure
cd terraform/environments/dev
terraform init
terraform plan -var-file=dev.tfvars
terraform apply -var-file=dev.tfvars
```

##### Cluster Restoration

```bash
# Restore EKS cluster
aws eks create-cluster \
    --name bankingapp-dev-eks \
    --role-arn <cluster-role-arn> \
    --resources-vpc-config subnetIds=<subnet-ids>,securityGroupIds=<sg-ids> \
    --region us-east-1
```

#### Full Environment Recovery

##### Complete Environment Restoration

1. **Restore Infrastructure**: Restore VPC, EKS, RDS using Terraform
2. **Restore Database**: Restore database from backup
3. **Restore Applications**: Deploy applications using Helm
4. **Verify Services**: Verify all services are running
5. **Test Functionality**: Test all functionality

See [Disaster Recovery Runbook](docs/runbooks/disaster-recovery.md) for detailed procedures.

### High Availability

#### Multi-AZ Deployment

- **RDS Multi-AZ**: Enable multi-AZ for production RDS instances
- **EKS Multi-AZ**: Deploy EKS nodes across multiple AZs
- **Load Balancing**: Use load balancers for high availability

#### Load Balancing

- **Application Load Balancer**: Use ALB for application load balancing
- **Network Load Balancer**: Use NLB for network load balancing
- **Health Checks**: Configure health checks for load balancers

#### Auto-Scaling

- **Horizontal Pod Autoscaling**: Enable HPA for automatic pod scaling
- **Cluster Autoscaling**: Enable cluster autoscaling for node scaling
- **Database Read Replicas**: Use read replicas for database scaling

#### Failover Procedures

##### Automated Failover

- **RDS Multi-AZ**: Automatic failover to standby instance
- **EKS Multi-AZ**: Automatic pod distribution across AZs
- **Load Balancer**: Automatic traffic distribution

##### Manual Failover

```bash
# Manual database failover
aws rds reboot-db-instance \
    --db-instance-identifier dev-db \
    --force-failover \
    --region us-east-1

# Manual pod failover
kubectl delete pod <pod-name> -n default
```

### Disaster Recovery Testing

#### Regular Testing

- **Monthly Tests**: Conduct monthly DR tests for staging
- **Quarterly Tests**: Conduct quarterly DR tests for production
- **Annual Tests**: Conduct annual full DR tests

#### Test Procedures

1. **Backup Verification**: Verify backups are working
2. **Recovery Testing**: Test recovery procedures
3. **Failover Testing**: Test failover procedures
4. **Documentation Review**: Review and update documentation

#### Test Results

- **Document Results**: Document all test results
- **Identify Issues**: Identify and fix issues
- **Update Procedures**: Update procedures based on test results

#### Continuous Improvement

- **Regular Reviews**: Regular reviews of DR procedures
- **Updates**: Update procedures based on changes
- **Training**: Train team on DR procedures

---

## Additional Documentation

For more detailed information, please refer to the following documentation:

### Runbooks

- [Incident Response Runbook](docs/runbooks/incident-response.md) - Incident response procedures
- [Database Backup and Restore Runbook](docs/runbooks/database-backup-restore.md) - Database backup and restore procedures
- [Deployment Rollback Runbook](docs/runbooks/deployment-rollback.md) - Deployment rollback procedures
- [Scaling Procedures Runbook](docs/runbooks/scaling-procedures.md) - Scaling procedures
- [Security Incident Response Runbook](docs/runbooks/security-incident-response.md) - Security incident response procedures
- [Monitoring and Alerts Runbook](docs/runbooks/monitoring-alerts.md) - Monitoring and alerting procedures
- [Maintenance Windows Runbook](docs/runbooks/maintenance-windows.md) - Maintenance window procedures

### Operational Documentation

- [Architecture Documentation](docs/ARCHITECTURE.md) - Detailed architecture documentation
- [API Documentation](docs/API_DOCUMENTATION.md) - API endpoints and usage
- [Networking Documentation](docs/NETWORKING.md) - Network architecture and configuration
- [Security Documentation](docs/SECURITY.md) - Security policies and procedures
- [Cost Management Documentation](docs/COST_MANAGEMENT.md) - Cost management and optimization
- [Disaster Recovery Documentation](docs/DISASTER_RECOVERY.md) - Disaster recovery procedures

---

## Contributing

Please read [CONTRIBUTING.md](CONTRIBUTING.md) for details on our code of conduct and the process for submitting pull requests.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

For support, please contact the DevOps team or open an issue in the repository.

---

**Last Updated**: 2024-01-01  
**Version**: 1.0.0  
**Maintained by**: DevOps Team

