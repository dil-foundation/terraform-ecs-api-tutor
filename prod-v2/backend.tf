terraform {
  backend "s3" {
    bucket = "dil-prod-v2-terraform-state"
    key    = "prod-v2/terraform.tfstate"
    region = "us-east-1"

    # Enable state locking with DynamoDB (recommended for production)
    dynamodb_table = "dil-prod-v2-terraform-locks"
    encrypt        = true
  }
}

