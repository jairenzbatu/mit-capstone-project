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

  required_version = ">= 1.2.0"
}

# Configure AWS Provider
provider "aws" {
  region = var.region
  alias  = "primary"
}

provider "aws" {
  region = var.secondary_region # Secondary region
  alias  = "secondary"
}

# Jairenz MBA Public Key
resource "aws_key_pair" "jb_mba_key" {
  provider   = aws.primary
  key_name   = "jb_mba_key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCfjezEkEyaLuEyT8usQHX1MS7QhbRAr83S8qQUeybjYS0BcVG3t5jzEBQinDmWpGpEzUrNVWdunzpabEdNP/s6prg3yMYI0okMRYL9kFEuDmzrlZXijHVOYpp6wDVOZX2TFdDnEpr5zcuyYIPxU+tUpQULXjWLOJQkVgDvsHfp9w2kM2odjY3sbrMl6o80qBlh8wZHQaduSnv8bkaMUrOyl5mZ27VTf9btTCGRmGKlUKbG6N6HQgRZvHJQoI9HbesxVpE7ZAsy/UQ7k52i3l72/jRIqaFr7MxMa6KvUtGUBcYLdmGSHxqeKzSDOSFEWVXyd0pMpxDMLAUKMTFtRMcfKQONVoW8ltIdVw+UW9KWAHzG+b6okUB0bXj0jpYZBRsdvuAb7VzJ0i50BCXhu6UUkSC0rK8cTc6p9CQpVgbIjqZiH1zU82nYhhUDRDLQf51BxWQUTzGy0rHxHSAvWroBJ/0iLFjuhKTPlXd/N/c9B9gWOnMb8f+wBYQ/mL8c7Hc= jairenzbatu@Js-MacBook.local"
}

# IAM Profiles, S3 Bucket Policy
# IAM Role for EC2
resource "aws_iam_role" "ec2_s3_role" {
  name = "EC2S3AccessRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "ec2.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

# Attach policy to role
resource "aws_iam_role_policy_attachment" "attach_s3_full_policy" {
  role       = aws_iam_role.ec2_s3_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

# IAM Instance Profile (for EC2 ASG)
resource "aws_iam_instance_profile" "ec2_profile" {
  name = var.ec2_iam_profile
  role = aws_iam_role.ec2_s3_role.name
}

# Primary RDS Instance Configuration
resource "aws_db_subnet_group" "rds_subnet_group" {
  provider   = aws.primary
  name       = "rds_subnet_group"
  subnet_ids = [aws_subnet.rds_subnet_a.id, aws_subnet.rds_subnet_b.id]

  tags = {
    Name = "Primary DB Subnet Group"
  }
}

resource "aws_db_instance" "default" {
  provider                = aws.primary
  allocated_storage       = 10
  storage_type            = "gp2"
  engine                  = "mysql"
  engine_version          = "8.0.39"
  instance_class          = "db.t3.medium"
  identifier              = "mydb"
  username                = var.rds_root_user
  password                = var.rds_root_password
  multi_az                = true
  backup_retention_period = 2
  backup_window           = "03:00-06:00"
  maintenance_window      = "sun:07:00-sun:08:00"

  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.rds_subnet_group.name

  tags = {
    Name = "Primary Database Instance"
  }

  skip_final_snapshot = true
}
output "Rds_Address" {
  value = aws_db_instance.default.address
}

# Secondary RDS Read Replica
resource "aws_db_subnet_group" "secondary_rds_subnet_group" {
  provider   = aws.secondary
  name       = "secondary_rds_subnet_group"
  subnet_ids = [aws_subnet.secondary_rds_subnet_a.id, aws_subnet.secondary_rds_subnet_b.id]

  tags = {
    Name = "Secondary DB Subnet Group"
  }
}

resource "aws_db_instance" "replica" {
  provider            = aws.secondary
  instance_class      = "db.t3.micro"
  replicate_source_db = aws_db_instance.default.arn
  identifier          = "secondary-read-replica"
  engine              = "mysql"
  engine_version      = "8.0.39"
  publicly_accessible = false
  storage_type        = "gp2"
  skip_final_snapshot = true

  vpc_security_group_ids = [aws_security_group.secondary_rds_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.secondary_rds_subnet_group.name


  tags = {
    Name = "Secondary DB Cluster"
  }
}
output "Replica_Rds_Address" {
  value = aws_db_instance.replica.address
}

# Application Load Balancer Configuration
resource "aws_lb" "snipe_alb" {
  provider           = aws.primary
  name               = "snipe-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.public_alb_a_subnet.id, aws_subnet.public_alb_b_subnet.id]
}

# https listener
resource "aws_lb_listener" "https_listener" {
  provider          = aws.primary
  load_balancer_arn = aws_lb.snipe_alb.arn
  port              = "443"
  protocol          = "HTTPS"

  # Specify the SSL certificate for HTTPS termination
  ssl_policy      = "ELBSecurityPolicy-2016-08" # Optional: You can customize this
  certificate_arn = var.ssl_cert                # Replace with your certificate ARN

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.private_application_tg.arn # Your target group for HTTP traffic (port 80)
  }
}

# http listener with redirect
resource "aws_lb_listener" "http_listener" {
  provider          = aws.primary
  load_balancer_arn = aws_lb.snipe_alb.arn
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

resource "aws_lb_target_group" "private_application_tg" {
  provider = aws.primary
  name     = "EC2--Target-Group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.app_vpc.id

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
  value = aws_lb.snipe_alb.dns_name
}

# AWS EC2 Launch Template
resource "aws_launch_template" "snipe_ec2_lt" {
  provider      = aws.primary
  name          = "snipe_ec2_launch_template"
  description   = "SnipeIT Launch Template"
  image_id      = var.instance_image_id
  instance_type = var.instance_type

  block_device_mappings {
    device_name = "/dev/xvda" # Default root volume for Amazon Linux
    ebs {
      volume_size           = 12    # Set disk size to 12 GB
      volume_type           = "gp3" # Use gp3 for better performance
      delete_on_termination = true
    }
  }

  key_name               = var.instance_key
  vpc_security_group_ids = [aws_security_group.app_sg.id]

  user_data = base64encode(templatefile("${path.module}/userdata.tpl", {
    db_host       = aws_db_instance.default.address
    db_root_user  = var.rds_root_user
    db_root_pass  = var.rds_root_password
    lb_url        = aws_lb.snipe_alb.dns_name
    app_subdomain = var.app_subdomain
  }))

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_profile.name
  }

}

# Application AutoScaling Group
resource "aws_autoscaling_group" "snipe-asg" {
  provider         = aws.primary
  min_size         = 1
  max_size         = 1
  desired_capacity = 1
  # launch_configuration = aws_launch_configuration.snipe_ec2.name
  launch_template {
    id      = aws_launch_template.snipe_ec2_lt.id
    version = aws_launch_template.snipe_ec2_lt.latest_version
  }
  vpc_zone_identifier = [aws_subnet.public_app_subnet_a.id, aws_subnet.public_app_subnet_b.id]
  name                = "snipe-asg"
  target_group_arns   = [aws_lb_target_group.private_application_tg.arn]
}
resource "aws_autoscaling_attachment" "snipe_app" {
  provider               = aws.primary
  autoscaling_group_name = aws_autoscaling_group.snipe-asg.id
  lb_target_group_arn    = aws_lb_target_group.private_application_tg.arn
}

# Route 53 Hosted Zone
data "aws_route53_zone" "asset_url" {
  name = "jairenz.xyz."
}

# Primary (Active) DNS Record
resource "aws_route53_record" "asset_url_primary" {
  zone_id = data.aws_route53_zone.asset_url.zone_id
  name    = var.app_subdomain
  type    = "A"

  failover_routing_policy {
    type = "PRIMARY"
  }

  alias {
    name                   = aws_lb.snipe_alb.dns_name
    zone_id                = aws_lb.snipe_alb.zone_id
    evaluate_target_health = true
  }

  set_identifier = "primary"

  lifecycle {
    create_before_destroy = true
  }
}

# Outputs for Secondary Instance
output "Secondary_VPC_ID" {
  value = aws_vpc.secondary_app_vpc.id
}
output "Secondary_RouteTable" {
  value = aws_route_table.secondary_public_rt.id
}