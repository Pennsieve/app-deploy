## app-deploy

Deploys an application to the cloud

- AWS

To build:

arm64:

`docker build -f Dockerfile_arm64 --progress=plain -t pennsieve/app-deploy .`

x86 (64bit):

`docker build --progress=plain -t pennsieve/app-deploy .`

To view supported commands: Run `make`

## To create infrastructure:

- Copy the `application.env.sample` file in the `dev` or `prod` `configs` folders in `application-deployments` to `<applicationName>.env`. Update the file to match your desired application config, and then update the `docker-compose.yml` file to the location of the `<applicationName>.env` file for the application you would like to create/deploy. The `configs` folder is setup such that multiple application configs can stored in that folder, and you can update the `docker-compose.yml` file to point to the config of the deploy application you would like to deploy.


`make create`

Retrieve `app_ecr_repository` and `post_processor_ecr_repository` details from `apply.log` file, in the application-deployments folder: 

`aws_account_id.dkr.ecr.region.amazonaws.com/repositoryName`
`aws_account_id.dkr.ecr.region.amazonaws.com/postProcessorRepositoryName`

`make deploy ACCOUNT=<aws_account_id> REGION=<region> APP_REPO_NAME=<repositoryName>  AWS_PROFILE=<profile> POST_PROCESSOR_REPO_NAME=<postProcessorRepositoryName> ENTRYPOINT=main.<extension> SOURCE_CODE_REPO=<source_code_repo>`

`extension` - `py` or `R`

Also keep track of: `app_gateway_url`. That URL will be used when you setup the application.

Example source code repositories (SOURCE_CODE_REPO):

- Python - https://github.com/Penn-I3H/python-application-template


