cd $1
export TF_DATA_DIR=$2

if [ $7 = "destroy" ]; then
  echo "Running destroy ..."
  terraform apply -destroy -auto-approve -var-file=$5 > $2/destroy.log
else
  echo "Running init and plan ..."
  terraform init -force-copy -backend-config=$3
  terraform plan -out=$4 -var-file=$5

  echo "Generating output ..."
  terraform output
  echo "Generating graph ..."
  terraform graph -draw-cycles | dot -Tsvg > $6

  if [ $7 = "create" ]; then
   echo "Running apply ..."
   terraform apply $4 > $2/apply.log
  fi
fi