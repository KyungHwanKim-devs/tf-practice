terraform {
  backend "s3" {
    bucket = "tf-prac-backend-s3-kkh"
    key    = "prod/data-stores/mysql/terraform.tfstate"
    region = "ap-northeast-2"

    dynamodb_table = "tf-backend-lock"
    encrypt        = true
  }

}
provider "aws" {
  region = "ap-northeast-2"
}



resource "aws_db_instance" "example" {
  identifier_prefix   = "tf-up-and-running"
  engine              = "mysql"
  allocated_storage   = 10
  instance_class      = "db.t2.micro"
  db_name             = "example_db_prod"
  username            = "admin"
  skip_final_snapshot = true

  password = "sigkgk1!"

}


output "address" {
  value = aws_db_instance.example.address
}

output "port" {
  value = aws_db_instance.example.port
}
