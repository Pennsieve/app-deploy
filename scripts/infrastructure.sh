#!/bin/sh

echo "RUNNING IN ENVIRONMENT: $ENVIRONMENT"

DEPLOYMENTS_DIR="/service/application-deployments"
export TF_DATA_DIR="${DEPLOYMENTS_DIR}/${ENVIRONMENT}/${APP_GIT_REPOSITORY}"
mkdir -p $TF_DATA_DIR

TERRAFORM_DIR="/service/terraform"
cd $TERRAFORM_DIR
VAR_FILE="$TF_DATA_DIR/${ENVIRONMENT}.tfvars"
BACKEND_FILE="$TF_DATA_DIR/${ENVIRONMENT}.tfbackend"
PLAN_FILE="$TF_DATA_DIR/tfplan"
SVG_FILE="$TF_DATA_DIR/graph.svg"

echo "Creating backend config"
  /bin/cat > "$TF_DATA_DIR/${ENVIRONMENT}.tfbackend" <<EOL
bucket  = "${TF_REMOTE_BUCKET}"
key     = "${ENVIRONMENT}/${APP_GIT_REPOSITORY}/terraform.tfstate"
EOL

echo "Creating tfvars config"
  /bin/cat > "$TF_DATA_DIR/${ENVIRONMENT}.tfvars" <<EOL
region = "${AWS_DEFAULT_REGION}"
az = ["a", "b", "c", "d", "e", "f"]
app_repository = "app"
post_processor_repository = "post-processor"
workflow_manager_repository = "workflow-manager"
api_host = "${API_HOST}"
api_host2 = "${API_HOST2}"
pennsieve_agent_home = "/tmp"
pennsieve_upload_bucket = "${PENNSIEVE_UPLOAD_BUCKET}"
api_key_secret = {
    "${API_KEY}" = "${API_SECRET}"
}
environment = "${ENVIRONMENT}"
app_name = "${APP_GIT_REPOSITORY}"
app_cpu = "${APP_CPU:-2048}"
app_memory = "${APP_MEMORY:-4096}"
post_processor_cpu = "${POST_PROCESSOR_CPU:-2048}"
post_processor_memory = "${POST_PROCESSOR_MEMORY:-4096}"
wm_cpu = "${WM_CPU:-2048}"
wm_memory = "${WM_MEMORY:-4096}"
EOL

if [ $1 = "destroy" ]; then
  echo "Running destroy ..."
  terraform apply -destroy -auto-approve -var-file=$VAR_FILE > $TF_DATA_DIR/destroy.log
else
  echo "Running init and plan ..."
  terraform init -force-copy -backend-config=$BACKEND_FILE
  terraform plan -out=$PLAN_FILE -var-file=$VAR_FILE

  echo "Generating output ..."
  terraform output
  echo "Generating graph ..."
  terraform graph -draw-cycles | dot -Tsvg > $SVG_FILE

  if [ $1 = "create" ]; then
   echo "Running apply ..."
   terraform apply $PLAN_FILE > $TF_DATA_DIR/apply.log
  fi
fi

echo "DONE RUNNING IN ENVIRONMENT: $ENVIRONMENT"