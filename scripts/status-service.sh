#!/bin/sh

cd $1

if [ $2 = "create-status-service" ]; then
  echo "creating ..."
  # terraform validate
  terraform init > init.log
  export TF_LOG_PATH="error.log"
  export TF_LOG=TRACE
  terraform plan -out=tfplan > plan.log
  terraform apply tfplan
else
  echo "deleting ..."
  terraform apply -destroy -auto-approve
fi