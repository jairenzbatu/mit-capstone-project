# Variables that will be declared via plan
variable "secondary_app_security_group" {
  default = "test"
}
variable "pub_app_subnet_a" {
  default = "test"
}
variable "pub_app_subnet_b" {
  default = "test"
}
# name = EC2--Target-Group return = arn
variable "app_private_tg" {
  default = "test"
}
variable "ec2_iam_profile" {
  default = "EC2S3InstanceProfile"
}
# General Variables
variable "instance_key" {
  default = "secondary_jb_mba_key"
}
variable "rds_host_url" {
  default = "localhost"
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
  default = "arn:aws:acm:ap-northeast-1:207567802974:certificate/89856db4-3464-4f23-9972-38295c10dbfb"
}

# variables passed from primary infrastructure
variable "secondary_vpc" {
  default = "test"
}
# variables passed from primary infrastructure
variable "secondary_public_rt" {
  default = "test"
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
variable "secondary_instance_type" {
  default = "t2.medium"
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