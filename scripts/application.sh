#!/bin/sh

cd $1
export TF_DATA_DIR="${1}/applications/${APP_NAME}"
mkdir -p $TF_DATA_DIR
echo $TF_DATA_DIR
PLAN_FILE="$TF_DATA_DIR/tfplan"

echo "Creating tfvars config"
  /bin/cat > "${TF_DATA_DIR}/${APP_NAME}.tfvars" <<EOL
region = "${AWS_DEFAULT_REGION}"
environment = "${ENVIRONMENT}"
app_name = "${APP_NAME}"
app_cpu = "${APP_CPU:-2048}"
app_memory = "${APP_MEMORY:-4096}"
app_git_url = "${APP_GIT_REPOSITORY}"
EOL

echo "Creating backend config"
  /bin/cat > "$TF_DATA_DIR/${APP_NAME}.tfbackend" <<EOL
bucket  = "${APP_REMOTE_BUCKET}"
key     = "${ENVIRONMENT}/${APP_GIT_REPOSITORY}/${APP_NAME}.tfstate"
EOL

if [ $2 = "create-application" ]; then
  echo "creating ..."
  terraform init -force-copy -backend-config="$TF_DATA_DIR/${APP_NAME}.tfbackend"
  export TF_LOG=TRACE
  terraform plan -out=$PLAN_FILE -var-file="$TF_DATA_DIR/${APP_NAME}.tfvars"
  terraform apply $PLAN_FILE
else
  echo "deleting ..."
  terraform apply -destroy -auto-approve -var-file="$TF_DATA_DIR/${APP_NAME}.tfvars"
fi