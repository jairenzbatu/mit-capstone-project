# General Variables
variable "instance_key" {
  default = "jb_mba_key"
}
variable "rds_root_user" {
  default = "dbuser"
}
variable "rds_root_password" {
  default = "dbpassword"
}
variable "app_subdomain" {
  default = "mit.jairenz.xyz"
}
variable "ssl_cert" {
  default = "arn:aws:acm:ap-southeast-1:207567802974:certificate/53d35c46-a847-4700-a1b5-842d0b3d4001"
}
variable "ec2_iam_profile" {
  default = "EC2S3InstanceProfile"
}

# Primary Region Variables
variable "region" {
  default = "ap-southeast-1"
}
variable "instance_image_id" {
  default = "ami-0c4e27b0c52857dd6"
}
variable "az_zone_a" {
  default = "ap-southeast-1a"
}
variable "az_zone_b" {
  default = "ap-southeast-1b"
}
variable "instance_type" {
  default = "t2.medium"
}
variable "profile_name" {
  default = "default"
}
variable "vpc_cidr" {
  default = "10.0.0.0/16"
}
variable "public_alb_subnet_a_cidr" {
  default = "10.0.10.0/24"
}
variable "public_alb_subnet_b_cidr" {
  default = "10.0.20.0/24"
}
variable "public_app_subnet_a_cidr" {
  default = "10.0.110.0/24"
}
variable "public_app_subnet_b_cidr" {
  default = "10.0.120.0/24"
}
variable "public_rds_subnet_a_cidr" {
  default = "10.0.210.0/24"
}
variable "public_rds_subnet_b_cidr" {
  default = "10.0.220.0/24"
}

# Secondary Region Variables
variable "secondary_region" {
  default = "ap-northeast-1"
}
variable "secondary_instance_image_id" {
  default = "ami-0b28346b270c7b165"
}
variable "secondary_az_zone_a" {
  default = "ap-northeast-1a"
}
variable "secondary_az_zone_b" {
  default = "ap-northeast-1c"
}
variable "secondary_vpc_cidr" {
  default = "10.20.0.0/16"
}
variable "secondary_public_alb_subnet_a_cidr" {
  default = "10.20.10.0/24"
}
variable "secondary_public_alb_subnet_b_cidr" {
  default = "10.20.20.0/24"
}
variable "secondary_public_app_subnet_a_cidr" {
  default = "10.20.110.0/24"
}
variable "secondary_public_app_subnet_b_cidr" {
  default = "10.20.120.0/24"
}
variable "secondary_public_rds_subnet_a_cidr" {
  default = "10.20.210.0/24"
}
variable "secondary_public_rds_subnet_b_cidr" {
  default = "10.20.220.0/24"
}