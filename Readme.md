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
`aws_account_id.dkr.ecr.region.amazonaws.com/postProcessorRepositoryName`

`make deploy ACCOUNT=<aws_account_id> REGION=<region> REPO_NAME=<repositoryName>  AWS_PROFILE=<profile> POST_PROCESSOR_REPO_NAME=<postProcessorRepositoryName> ENTRYPOINT=main.<extension> SOURCE_CODE_REPO=<source_code_repo>`

Also keep track of: `app_gateway_url`
