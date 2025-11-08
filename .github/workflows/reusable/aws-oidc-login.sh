#!/bin/bash
set -e

ROLE_ARN=$1
AWS_REGION=$2

echo "🔐 Configuring AWS OIDC credentials..."
aws configure set region "$AWS_REGION"
aws sts get-caller-identity

echo "Assuming role: $ROLE_ARN"
aws-actions/configure-aws-credentials@v2 \
  --role-to-assume "$ROLE_ARN" \
  --aws-region "$AWS_REGION" \
  --audience sts.amazonaws.com

echo "Logging in to AWS ECR..." 
aws ecr get-login-password --region "$AWS_REGION" | docker login --username AWS --password-stdin "$REGISTRY"

echo "✅ AWS OIDC setup complete."