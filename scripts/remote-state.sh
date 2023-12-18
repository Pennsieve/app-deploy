cd $1

if [ $2 = "create-backend" ]; then
  echo "creating ..."
  terraform init
  terraform plan -out=tfplan
  terraform apply tfplan
else
  echo "deleting ..."
  terraform apply -destroy -auto-approve
fi