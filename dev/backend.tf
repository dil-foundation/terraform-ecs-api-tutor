terraform {
  backend "s3" {
    bucket = "dil-prod-terraform-state"
    key    = "dev/terraform.tfstate"
    region = "us-east-1"

    # Enable state locking with DynamoDB
    # dynamodb_table = "dil-prod-terraform-locks"
    # encrypt        = true
  }
}
