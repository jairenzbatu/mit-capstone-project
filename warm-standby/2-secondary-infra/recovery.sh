#!/bin/bash

# start recovery process
echo "STARTING RECOVERY PROCESS"
terraform init

# import the secondary rds instance
echo "IMPORTING SECONDARY RDS INSTANCE"
terraform import aws_db_instance.secondary_rds_import secondary-read-replica

# declare primary instance dependent resources
secondary_vpc=$(aws ec2 describe-vpcs --region ap-northeast-1 --filters "Name=tag:Name,Values=secondary-app-vpc" --query "Vpcs[0].VpcId" --output text --no-cli-pager)
secondary_app_sg=$(aws ec2 describe-security-groups --filters "Name=group-name,Values=secondary_allow_ssh_http_on_app" --query "SecurityGroups[*].GroupId" --output text --no-cli-pager --region ap-northeast-1)
secondary_alb_tg=$(aws elbv2 describe-target-groups --names "EC2--Target-Group" --query "TargetGroups[*].TargetGroupArn" --output text --no-cli-pager --region ap-northeast-1)
secondary_app_subnet_a=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=secondary_public-subnet-a" --query "Subnets[*].SubnetId" --output text --no-cli-pager --region ap-northeast-1)
secondary_app_subnet_b=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=secondary_public-subnet-b" --query "Subnets[*].SubnetId" --output text --no-cli-pager --region ap-northeast-1)

# optional terraform plan
terraform plan \
-var="secondary_vpc="${secondary_vpc}"" \
-var="secondary_app_security_group="${secondary_app_sg}"" \
-var="pub_app_subnet_a="${secondary_app_subnet_a}"" \
-var="pub_app_subnet_b="${secondary_app_subnet_b}"" \
-var="app_private_tg="${secondary_alb_tg}""

# apply the terraform plan
terraform apply -auto-approve \
-var="secondary_vpc="${secondary_vpc}"" \
-var="secondary_app_security_group="${secondary_app_sg}"" \
-var="pub_app_subnet_a="${secondary_app_subnet_a}"" \
-var="pub_app_subnet_b="${secondary_app_subnet_b}"" \
-var="app_private_tg="${secondary_alb_tg}""