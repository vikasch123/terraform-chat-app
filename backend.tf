terraform {
  backend "s3" {
    bucket         = "my-unique-terraform-backend-s3-738086"
    key            = "terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "my-table"
  }
}





  
