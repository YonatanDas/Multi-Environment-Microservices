terraform {
  backend "s3" {
    bucket         = "banking-terraform-state-18.10.25" # specify your bucket name
    key            = "envs/prod/terraform.tfstate" # specify the path to your state file in the bucket
    region         = "us-east-1" # specify your bucket region
    dynamodb_table = "terraform-locks" # specify your DynamoDB table for state locking
    encrypt        = true # enable encryption at rest
  }
}