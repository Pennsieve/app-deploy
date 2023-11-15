## app-deploy

Deploys an application to the cloud (AWS)

To build:

arm64:

`docker build -f Dockerfile_arm64 --progress=plain -t pennsieve/app-deploy .`

x86 (64bit):

`docker build --progress=plain -t pennsieve/app-deploy .`

Supported commands:

`make`

`make create`

Retrieve details from `app_ecr_repository` and `post_processor_ecr_repository` output: 

`aws_account_id.dkr.ecr.region.amazonaws.com/repositoryName`

`make deploy ACCOUNT=<aws_account_id> REGION=<region> REPO=<repositoryName>  AWS_PROFILE=<profile> POST_PROCESSOR_REPO=<postProcessorRepositoryName>`

Also keep track of: `app_gateway_url`
