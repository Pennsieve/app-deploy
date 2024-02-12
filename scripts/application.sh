#!/bin/sh

cd $1

echo "Creating tfvars config"
  /bin/cat > "${APP_NAME}.tfvars" <<EOL
region = "${AWS_DEFAULT_REGION}"
environment = "${ENVIRONMENT}"
app_name = "${APP_NAME}"
app_cpu = "${APP_CPU:-2048}"
app_memory = "${APP_MEMORY:-4096}"
app_git_url = "${APP_GIT_REPOSITORY}"
EOL

echo "Creating backend config"
  /bin/cat > "${APP_NAME}.tfbackend" <<EOL
bucket  = "${APP_REMOTE_BUCKET}"
key     = "${ENVIRONMENT}/${APP_GIT_REPOSITORY}/${APP_NAME}.tfstate"
EOL

if [ $2 = "create-application" ]; then
  echo "creating ..."
  terraform init -force-copy -backend-config="${APP_NAME}.tfbackend"
  export TF_LOG=TRACE
  terraform plan -out=tfplan -var-file="${APP_NAME}.tfvars"
  terraform apply tfplan
else
  echo "deleting ..."
  terraform apply -destroy -auto-approve
fi