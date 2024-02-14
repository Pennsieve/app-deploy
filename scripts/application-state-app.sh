#!/bin/sh

cd $1

if [ $2 = "create-application-state-app" ]; then
  echo "creating ..."
  terraform init
  terraform plan -out=tfplan > plan.log
  terraform apply tfplan > apply.log
else
  echo "deleting ..."
  terraform apply -destroy -auto-approve
fi