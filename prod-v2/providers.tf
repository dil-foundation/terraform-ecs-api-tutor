terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-2"

  default_tags {
    tags = {
      Environment = "prod-v2"
      Project     = "ai-tutor-backend"
      ManagedBy   = "terraform"
    }
  }
}

