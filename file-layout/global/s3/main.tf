provider "aws" {
  region = "ap-northeast-2"
}

terraform {
  backend "s3" {
    bucket = "tf-prac-backend-s3-kkh"
    key    = "workspaces-example/terraform.tfstate"
    region = "ap-northeast-2"

    dynamodb_table = "tf-backend-lock"
    encrypt        = true
  }

}


resource "aws_s3_bucket" "tf-state" {
  bucket = "tf-prac-backend-s3-kkh"

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}


resource "aws_dynamodb_table" "tf-backend-lock" {
  name         = "tf-backend-lock"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}


resource "aws_instance" "app" {
  instance_type     = "t2.micro"
  availability_zone = "ap-northeast-2c"
  ami               = "ami-003bb1772f36a39a3"
}
