provider "aws" {
  region = "ap-northeast-2"

}

variable "number_e" {
  description = "a ex"
  type        = number
  default     = 42
}

variable "list_example" {
  type        = list(any)
  description = "An example of a list in tf"
  default     = ["a", "b", "c"]
}

variable "list_numeric_example" {
  type        = list(number)
  description = "an example of a numeric list tf"
  default     = [1, 2, 3]
}

variable "map_example" {
  type        = map(string)
  description = "an example of a map in tf"
  default = {
    "key" = "value"
  }
}

data "aws_vpc" "default" {
  default = true
}
data "aws_subnets" "default" {

}

output "subnets" {
  value = data.aws_subnets.default.ids
}


variable "object_example" {
  description = "An example of a structural type in tf"
  type = object({
    name    = string
    age     = number
    tags    = list(string)
    enabled = bool
  })
  default = {
    age     = 1
    enabled = false
    name    = "value"
    tags    = ["value"]
  }
}

variable "server_port" {
  type        = number
  description = "Http server port"
}


resource "aws_security_group" "appsg" {
  name = "tf-app-sg"
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


resource "aws_instance" "app" {
  instance_type          = "t2.micro"
  availability_zone      = "ap-northeast-2c"
  ami                    = "ami-003bb1772f36a39a3"
  vpc_security_group_ids = [aws_security_group.appsg.id]

  user_data = <<-EOF
                #!/bin/bash
                echo "Hello, World" > index.html
                nohup busybox httpd -f -p ${var.server_port} &
                EOF


  tags = {
    "Name" = "이름"
  }
}

resource "aws_launch_configuration" "asg_lc_exam" {
  image_id        = aws_instance.app.ami
  instance_type   = aws_instance.app.instance_type
  security_groups = [aws_security_group.appsg.id]

  user_data = <<-EOF
                #!/bin/bash
                echo "Hello, World" > index.html
                nohup busybox httpd -f -p ${var.server_port} &
                EOF

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

  min_size = 2
  max_size = 10



  tag {
    key                 = "Name"
    value               = "asg exam"
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


output "output" {
  value = aws_instance.app.public_ip
}

output "alb_dns_name" {
  value = aws_lb.alb_exam.dns_name
}


resource "aws_lb" "alb_exam" {
  name               = "alb-exam"
  load_balancer_type = "application"
  subnets            = data.aws_subnets.default.ids
  security_groups    = [aws_security_group.alb.id]

}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.alb_exam.arn
  port              = 80
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

  name = "tf-example-sg"

  ingress = [{
    cidr_blocks      = ["0.0.0.0/0"]
    description      = null
    from_port        = 80
    ipv6_cidr_blocks = null
    prefix_list_ids  = null
    protocol         = "tcp"
    security_groups  = null
    self             = null
    to_port          = 80
  }]

  egress = [{
    cidr_blocks      = ["0.0.0.0/0"]
    description      = null
    from_port        = 0
    ipv6_cidr_blocks = null
    prefix_list_ids  = null
    protocol         = "-1"
    security_groups  = null
    self             = null
    to_port          = 0
  }]

}

resource "aws_lb_target_group" "asg_tg" {
  name     = "tf-asg-tg-exam"
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
