## Application Infrastructure as Code (IAC)

This repo is for the terraform templates for automated application creation.

To build:

`docker build --progress=plain --no-cache -t edmore/application-iac .`

To run:

`docker run -v $(pwd)/terraform:/service/terraform --env-file ./aws.env edmore/application-iac`
