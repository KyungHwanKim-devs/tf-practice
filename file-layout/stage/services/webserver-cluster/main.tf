provider "aws" {
  region = "ap-northeast-2"
}

module "webserver_cluster" {
  source = "../../../modules/services/webserver-cluster"

  cluster_name           = "webserver-stage"
  db_remote_state_bucket = "tf-prac-backend-s3-kkh"
  db_remote_state_key    = "stage/data-stores/mysql/terraform.tfstate"

  instance_type = "t3.nano"
  min_size      = 2
  max_size      = 2

  custom_tags = {
    "key" = "value"
  }
}

resource "aws_security_group_rule" "allow_testing_inbound" {
  type              = "ingress"
  security_group_id = module.webserver_cluster.alb_security_group_id

  from_port   = 1234
  to_port     = 1234
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}
