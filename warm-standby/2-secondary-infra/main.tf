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
    key    = "warm-standby-secondary"
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

# # AWS EC2 Launch Template
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
  vpc_security_group_ids = [var.secondary_app_security_group]

  # Update the value of these
  user_data = base64encode(templatefile("${path.module}/userdata.tpl", {
    db_host       = aws_db_instance.secondary_rds_import.address
    db_root_user  = var.rds_root_user
    db_root_pass  = var.rds_root_password
    app_subdomain = var.app_subdomain
  }))

  iam_instance_profile {
    name = var.ec2_iam_profile
  }

}

# Application AutoScaling Group
resource "aws_autoscaling_group" "secondary_snipe_asg_import" {
  provider         = aws.secondary
  min_size         = 1
  max_size         = 1
  desired_capacity = 1
  name             = "secondary-snipe-asg"

  launch_template {
    id      = aws_launch_template.secondary_snipe_ec2_lt.id
    version = aws_launch_template.secondary_snipe_ec2_lt.latest_version
  }
  vpc_zone_identifier = [var.pub_app_subnet_a, var.pub_app_subnet_b]

  target_group_arns = [var.app_private_tg]

}
resource "aws_autoscaling_attachment" "secondary_snipe_app" {
  provider               = aws.secondary
  autoscaling_group_name = aws_autoscaling_group.secondary_snipe_asg_import.id
  lb_target_group_arn    = var.app_private_tg
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

  tags = {
    Name = "Secondary DB Cluster"
  }
}