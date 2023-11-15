To build:

`docker build -t pennsieve/app-wrapper .`

On arm64 architectures:

`docker build -f Dockerfile_arm64 -t pennsieve/app-wrapper .`

To run:

`docker-compose up --build`

To deploy:


`make create`

Retrieve details from `app_ecr_repository` output: 

`aws_account_id.dkr.ecr.region.amazonaws.com/repositoryName`

`make deploy ACCOUNT=<aws_account_id> REGION=<region> REPO=<repositoryName> AWS_PROFILE=<profile>`
