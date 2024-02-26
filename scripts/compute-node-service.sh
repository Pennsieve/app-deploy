#!/bin/sh

cd $1

if [ $2 = "create-compute-node" ]; then
  echo "creating ..."
  # terraform validate
  echo "running init ..."
  export TF_LOG_PATH="error.log"
  export TF_LOG=TRACE
  terraform init > init.log
  terraform plan -out=tfplan > plan.log
  terraform apply tfplan
else
  echo "deleting ..."
  terraform apply -destroy -auto-approve
fi