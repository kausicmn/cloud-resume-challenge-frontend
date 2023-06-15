terraform {
  required_providers {
    aws={
        source="hashicorp/aws"
        version= "5.2.0"
    }
  }
  #   backend "s3" {
  #   bucket = "tf-state-frontend-kausic"
  #   key    = "terraform-state"
  #   region = "us-east-1"
  # }
}
provider "aws" {
    region = "us-east-1"
  # Configuration options
}