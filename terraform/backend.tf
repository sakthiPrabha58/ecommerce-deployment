terraform {
  required_version = ">= 1.5.0"

  backend "s3" {
    bucket         = "terraform-tf-state-bucket-devops"   
    key            = "terraform/terraform.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "terraform-tf-lock"
    encrypt        = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
