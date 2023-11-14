To build:

`docker build -t pennsieve/app-wrapper .`

On arm64 architectures:

`docker build -f Dockerfile_arm64 -t pennsieve/app-wrapper .`

To run:

`docker-compose up --build`

To deploy:

```
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <accountNumber>.dkr.ecr.us-east-1.amazonaws.com

docker build <-f Dockerfile> -t pennsieve/app-wrapper .

docker tag pennsieve/app-wrapper:latest <accountNumber>.dkr.ecr.us-east-1.amazonaws.com/pennsieve/app-wrapper

docker push <accountNumber>.dkr.ecr.us-east-1.amazonaws.com/pennsieve/app-wrapper

 aws lambda update-function-code \
      --region us-east-1 \
      --function-name app-wrapper \
      --image-uri <accountNumber>.dkr.ecr.us-east-1.amazonaws.com/pennsieve/app-wrapper:latest

```