variable "environment" {
  description = "Deployment environment (e.g. dev, prod)"
  type        = string
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "name_prefix" {
  type    = string
  default = "banking"
}

variable "aws_account_id" {
  description = "The AWS Account ID where resources will be created"
  type        = string
}

variable "aws_region" {
  description = "The AWS region where resources will be created"
  type        = string
  default     = "us-east-1"
}