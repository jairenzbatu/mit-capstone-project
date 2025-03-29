#!/bin/bash

# start recovery process
echo "STARTING RECOVERY PROCESS"
terraform init

terraform plan
terraform apply -auto-approve