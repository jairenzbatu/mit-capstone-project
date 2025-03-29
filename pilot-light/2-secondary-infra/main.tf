# Written by Jairenz Batu
# jairenz.batu@gmail.com
# Capstone Project - MIT
# Tarlac State University - College of Computer Studies

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }
  backend "s3" {
    bucket = "mit-pilot-secondary"
    key    = "pilot-light-secondary"
    region = "ap-northeast-1"
  }

  required_version = ">= 1.2.0"
}

# Configure AWS Provider
provider "aws" {
  region = var.secondary_region # Secondary region
  alias  = "secondary"
}

# Jairenz MBA Public Key
resource "aws_key_pair" "secondary_jb_mba_key" {
  provider   = aws.secondary
  key_name   = "secondary_jb_mba_key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCfjezEkEyaLuEyT8usQHX1MS7QhbRAr83S8qQUeybjYS0BcVG3t5jzEBQinDmWpGpEzUrNVWdunzpabEdNP/s6prg3yMYI0okMRYL9kFEuDmzrlZXijHVOYpp6wDVOZX2TFdDnEpr5zcuyYIPxU+tUpQULXjWLOJQkVgDvsHfp9w2kM2odjY3sbrMl6o80qBlh8wZHQaduSnv8bkaMUrOyl5mZ27VTf9btTCGRmGKlUKbG6N6HQgRZvHJQoI9HbesxVpE7ZAsy/UQ7k52i3l72/jRIqaFr7MxMa6KvUtGUBcYLdmGSHxqeKzSDOSFEWVXyd0pMpxDMLAUKMTFtRMcfKQONVoW8ltIdVw+UW9KWAHzG+b6okUB0bXj0jpYZBRsdvuAb7VzJ0i50BCXhu6UUkSC0rK8cTc6p9CQpVgbIjqZiH1zU82nYhhUDRDLQf51BxWQUTzGy0rHxHSAvWroBJ/0iLFjuhKTPlXd/N/c9B9gWOnMb8f+wBYQ/mL8c7Hc= jairenzbatu@Js-MacBook.local"
}

# Application Load Balancer Configuration
resource "aws_lb" "secondary_snipe_alb" {
  provider           = aws.secondary
  name               = "secondary-snipe-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.secondary_alb_sg.id]
  subnets            = [aws_subnet.secondary_public_alb_a_subnet.id, aws_subnet.secondary_public_alb_b_subnet.id]
}

# https listener
resource "aws_lb_listener" "secondary_https_listener" {
  provider          = aws.secondary
  load_balancer_arn = aws_lb.secondary_snipe_alb.arn
  port              = "443"
  protocol          = "HTTPS"

  # Specify the SSL certificate for HTTPS termination
  ssl_policy      = "ELBSecurityPolicy-2016-08" # Optional: You can customize this
  certificate_arn = var.ssl_cert                # Replace with your certificate ARN

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.secondary_private_application_tg.arn # Your target group for HTTP traffic (port 80)
  }
}

# http listener with redirect
resource "aws_lb_listener" "secondary_http_listener" {
  provider          = aws.secondary
  load_balancer_arn = aws_lb.secondary_snipe_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      protocol    = "HTTPS"
      port        = "443"
      status_code = "HTTP_301" # Permanent redirect (use HTTP_302 for temporary redirect)
    }
  }
}

resource "aws_lb_target_group" "secondary_private_application_tg" {
  provider = aws.secondary
  name     = "EC2--Target-Group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.secondary_vpc

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200,301,302"
  }
}
output "loadbalancer_Address" {
  value = aws_lb.secondary_snipe_alb.dns_name
}

# AWS EC2 Launch Template
resource "aws_launch_template" "secondary_snipe_ec2_lt" {
  provider      = aws.secondary
  name          = "secondary_snipe_ec2_launch_template"
  description   = "SnipeIT Launch Template"
  image_id      = var.secondary_instance_image_id
  instance_type = var.secondary_instance_type

  block_device_mappings {
    device_name = "/dev/xvda" # Default root volume for Amazon Linux
    ebs {
      volume_size           = 12    # Set disk size to 12 GB
      volume_type           = "gp3" # Use gp3 for better performance
      delete_on_termination = true
    }
  }

  key_name               = var.instance_key
  vpc_security_group_ids = [aws_security_group.secondary_app_sg.id]

  # Update the value of these
  user_data = base64encode(templatefile("${path.module}/userdata.tpl", {
    db_host       = aws_db_instance.secondary_rds_import.address
    db_root_user  = var.rds_root_user
    db_root_pass  = var.rds_root_password
    lb_url        = aws_lb.secondary_snipe_alb.dns_name
    app_subdomain = var.app_subdomain
  }))

  iam_instance_profile {
    name = var.ec2_iam_profile
  }

}

# Application AutoScaling Group
resource "aws_autoscaling_group" "secondary_snipe-asg" {
  provider         = aws.secondary
  min_size         = 1
  max_size         = 1
  desired_capacity = 1

  launch_template {
    id      = aws_launch_template.secondary_snipe_ec2_lt.id
    version = aws_launch_template.secondary_snipe_ec2_lt.latest_version
  }
  vpc_zone_identifier = [aws_subnet.secondary_public_app_subnet_a.id, aws_subnet.secondary_public_app_subnet_b.id]
  name                = "secondary-snipe-asg"
  target_group_arns   = [aws_lb_target_group.secondary_private_application_tg.arn]

}
resource "aws_autoscaling_attachment" "secondary_snipe_app" {
  provider               = aws.secondary
  autoscaling_group_name = aws_autoscaling_group.secondary_snipe-asg.id
  lb_target_group_arn    = aws_lb_target_group.secondary_private_application_tg.arn
}

# RDS Promotion from Replica to Primary
resource "aws_db_instance" "secondary_rds_import" {
  provider            = aws.secondary
  instance_class      = "db.t3.medium"
  identifier          = "secondary-read-replica"
  engine              = "mysql"
  engine_version      = "8.0.39"
  publicly_accessible = false
  storage_type        = "gp2"
  skip_final_snapshot = true
  multi_az            = true # Enabled Multi-AZ after promotion
  apply_immediately   = true

  tags = {
    Name = "Secondary DB Cluster"
  }
}
# Route 53 Hosted Zone
data "aws_route53_zone" "asset_url" {
  name = "jairenz.xyz."
}

# Secondary (Failover) DNS Record (Aligned with Existing Configuration)
resource "aws_route53_record" "asset_url" {
  zone_id = data.aws_route53_zone.asset_url.zone_id
  name    = var.app_subdomain
  type    = "A"

  failover_routing_policy {
    type = "SECONDARY"
  }

  alias {
    name                   = aws_lb.secondary_snipe_alb.dns_name
    zone_id                = aws_lb.secondary_snipe_alb.zone_id
    evaluate_target_health = true
  }

  set_identifier = "secondary"

  # Ensure creation only after the RDS read replica is ready
  depends_on = [aws_db_instance.secondary_rds_import]

  # Lifecycle rule to force replacement
  lifecycle {
    create_before_destroy = true
    ignore_changes        = [alias] # Keep alignment with existing behavior
  }
}