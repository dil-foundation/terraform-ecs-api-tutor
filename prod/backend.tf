terraform {
  backend "s3" {
    bucket = "dil-fnd-dev-terraform-state-1757934483"
    key    = "prod/terraform.tfstate"
    region = "us-east-2"

    # Enable state locking with DynamoDB
    dynamodb_table = "dil-fnd-dev-terraform-locks"
    encrypt        = true
  }
}
