## app-deploy

Deploys an application to the cloud. Supported platforms:

- AWS (prerequisite(s): [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html))

To build:

arm64:

`docker build -f Dockerfile_arm64 --progress=plain -t pennsieve/app-deploy .`

x86 (64bit):

`docker build --progress=plain -t pennsieve/app-deploy .`

To view supported commands: Run `make`

## To create infrastructure:

- Copy the *application.env.sample* file in the *dev* or *prod* *configs* folders in *application-deployments* to *`<applicationName>.env`*. Update the file to match your desired application config, and then update the *docker-compose.yml* file to the location of the *<applicationName>.env* file for the application you would like to create/deploy. The *configs* folder is setup such that multiple application configs can stored in that folder, and you can update the *docker-compose.yml* file to point to the config of the deploy application you would like to deploy.

- If an S3 storage does not currently exist to store the infrastructure state, run `make create-backend` to create it. Copy the output of that command (*aws_bucket_name*), and update the ENV variable *TF_REMOTE_BUCKET* in your env file.

`make create`

Retrieve *app_ecr_repository* and *post_processor_ecr_repository* details by running `make status`: 

*aws_account_id.dkr.ecr.region.amazonaws.com/repositoryName*
*aws_account_id.dkr.ecr.region.amazonaws.com/preProcessorRepositoryName*
*aws_account_id.dkr.ecr.region.amazonaws.com/postProcessorRepositoryName*

Also keep track of: *app_gateway_url*. That URL will be used when you update the application in Pennsieve.

## To deploy:

```
make deploy ACCOUNT=<aws_account_id> AWS_DEFAULT_REGION=<region> APP_REPO=aws_account_id.dkr.ecr.region.amazonaws.com/repositoryName AWS_PROFILE=<profile> POST_PROCESSOR_REPO=aws_account_id.dkr.ecr.region.amazonaws.com/postProcessorRepositoryName APP_GIT_REPOSITORY=<app_git_repository-without-scheme> WM_REPO=aws_account_id.dkr.ecr.region.amazonaws.com/workflowManagerRepositoryName PRE_PROCESSOR_REPO=aws_account_id.dkr.ecr.region.amazonaws.com/preProcessorRepositoryName APP_GIT_BRANCH=<branch> APP_NAME=<appName> WM_GIT_BRANCH=<branch> WM_GIT_REPOSITORY=github.com/Pennsieve/workflow-manager
```

Example source code repositories:

- Python - https://github.com/Penn-I3H/python-application-template (*APP_GIT_REPOSITORY* is `github.com/Penn-I3H/python-application-template`)