# provider "aws" {
#   region = "ap-northeast-2"
# }
locals {
  http_port    = 80
  any_port     = 0
  any_protocol = "-1"
  tcp_protocol = "tcp"
  all_ips      = ["0.0.0.0/0"]
}
variable "server_port" {
  type        = number
  description = "Http server port"
  default     = 8080
}

data "aws_vpc" "default" {
  default = true
}
data "aws_subnets" "default" {

}

data "template_file" "user_data" {
  template = file("${path.module}/user-data.sh")

  vars = {
    server_port = var.server_port
    db_address  = data.terraform_remote_state.db.outputs.address
    db_port     = data.terraform_remote_state.db.outputs.port
  }
}

# terraform {
#   backend "s3" {
#     bucket = "tf-prac-backend-s3-kkh"
#     key    = "stage/services/webserver-cluster/terraform.tfstate"
#     region = "ap-northeast-2"

#     dynamodb_table = "tf-backend-lock"
#     encrypt        = true
#   }
# }

data "terraform_remote_state" "db" {
  backend = "s3"

  config = {
    bucket = var.db_remote_state_bucket
    key    = var.db_remote_state_key
    region = "ap-northeast-2"
  }
}

resource "aws_security_group" "appsg" {
  name = "${var.cluster_name}-instance"
  ingress = [{
    cidr_blocks      = ["0.0.0.0/0"]
    description      = "HTTP"
    from_port        = var.server_port
    ipv6_cidr_blocks = null
    prefix_list_ids  = null
    protocol         = "tcp"
    security_groups  = null
    self             = null
    to_port          = var.server_port
  }]
}


# resource "aws_instance" "app" {
#   instance_type          = "t3.nano"
#   availability_zone      = "ap-northeast-2c"
#   ami                    = "ami-003bb1772f36a39a3"
#   vpc_security_group_ids = [aws_security_group.appsg.id]

#   user_data = <<-EOF
#                 #!/bin/bash
#                 echo "Hello, World" > index.html
#                 nohup busybox httpd -f -p ${var.server_port} &
#                 EOF


#   tags = {
#     "Name" = "이름"
#   }
# }

resource "aws_launch_configuration" "asg_lc_exam" {
  image_id        = "ami-003bb1772f36a39a3"
  instance_type   = var.instance_type
  security_groups = [aws_security_group.appsg.id]

  user_data = data.template_file.user_data.rendered

  lifecycle {
    create_before_destroy = true
  }

}

resource "aws_autoscaling_group" "asg_exam" {
  launch_configuration = aws_launch_configuration.asg_lc_exam.name
  vpc_zone_identifier  = data.aws_subnets.default.ids

  target_group_arns = [aws_lb_target_group.asg_tg.arn]
  # 디폴트는 ec2 인데, elb가 더 강력, 대상그룹의 상태를 확인
  health_check_type = "ELB"

  min_size = var.min_size
  max_size = var.max_size



  tag {
    key                 = "Name"
    value               = var.cluster_name
    propagate_at_launch = true
  }
}

resource "aws_lb_listener_rule" "asg" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 100

  condition {
    path_pattern {
      values = ["*"]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.asg_tg.arn
  }

}


# output "output" {
#   value = aws_instance.app.public_ip
# }




resource "aws_lb" "alb_exam" {
  name               = "${var.cluster_name}-alb-exam"
  load_balancer_type = "application"
  subnets            = data.aws_subnets.default.ids
  security_groups    = [aws_security_group.alb.id]

}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.alb_exam.arn
  port              = local.http_port
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "404:page not found"
      status_code  = 404
    }
  }
}

resource "aws_security_group" "alb" {

  name = "${var.cluster_name}-alb"

}

resource "aws_security_group_rule" "allow_http_inbound" {
  type              = "ingress"
  security_group_id = aws_security_group.alb.id

  cidr_blocks      = local.all_ips
  description      = null
  from_port        = local.http_port
  ipv6_cidr_blocks = null
  prefix_list_ids  = null
  protocol         = local.tcp_protocol
  self             = null
  to_port          = local.http_port

}

resource "aws_security_group_rule" "allow_http_outbound" {
  type              = "egress"
  security_group_id = aws_security_group.alb.id

  cidr_blocks      = local.all_ips
  description      = null
  from_port        = local.any_port
  ipv6_cidr_blocks = null
  prefix_list_ids  = null
  protocol         = local.tcp_protocol
  self             = null
  to_port          = local.any_port

}

resource "aws_lb_target_group" "asg_tg" {
  name     = "${var.cluster_name}-tf-asg-tg-exam"
  port     = var.server_port
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 15
    timeout             = 3
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}
