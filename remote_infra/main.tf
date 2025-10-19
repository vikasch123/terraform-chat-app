terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~>4.0"
    }
  }
  required_version = "~>1.0"
}


provider "aws" {
  alias  = "us-east-1"
  region = "us-east-1"
}

# creating the remote backend S3 which will store the state file 

resource "aws_s3_bucket" "mys3bucket" {
  bucket = "my-unique-terraform-backend-s3-738086"
  tags = {
    Name = "my-bucket"
  }
}

# creating the dynamoDB table for state locking

resource "aws_dynamodb_table" "dynamoDB-table-state-locking" {
  provider     = aws.us-east-1
  name         = "my-table"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"
  attribute {
    name = "LockID"
    type = "S"
  }
}
