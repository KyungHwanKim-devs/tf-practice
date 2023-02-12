output "subnets" {
  value = data.aws_subnets.default.ids
}

output "asg_name" {
  value       = aws_autoscaling_group.asg_exam.name
  description = "The name of autoscaling group"
}

output "alb_dns_name" {
  value = aws_lb.alb_exam.dns_name
}

output "alb_security_group_id" {
  value = aws_security_group.alb.id
}
