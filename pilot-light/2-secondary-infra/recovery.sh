#!/bin/bash

# start recovery process
echo "STARTING RECOVERY PROCESS"
terraform init

# import the secondary rds instance
echo "IMPORTING SECONDARY RDS INSTANCE"
terraform import aws_db_instance.secondary_rds_import secondary-read-replica

# declare primary instance dependent resources
secondary_vpc=$(aws ec2 describe-vpcs --region ap-northeast-1 --filters "Name=tag:Name,Values=secondary-app-vpc" --query "Vpcs[0].VpcId" --output text --no-cli-pager)
secondary_rt=$(aws ec2 describe-route-tables --region ap-northeast-1 --filters "Name=tag:Name,Values=secondary_public_rt" --query "RouteTables[0].RouteTableId" --output text --no-cli-pager)

# optional terraform plan
terraform plan \
-var="secondary_vpc="${secondary_vpc}"" \
-var="secondary_public_rt="${secondary_rt}""

# apply the terraform plan
terraform apply -auto-approve \
-var="secondary_vpc="${secondary_vpc}"" \
-var="secondary_public_rt="${secondary_rt}""