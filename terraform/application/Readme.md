To build:

`docker build -t edmore/cytof-pipeline .`

On amd64 architectures:

`docker build -f Dockerfile_amd64 -t edmore/cytof-pipeline .`

To run:

`docker-compose up --build`

To deploy:

```
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <accountNumber>.dkr.ecr.us-east-1.amazonaws.com

docker build <-f Dockerfile> -t edmore/cytof-pipeline .

docker tag edmore/cytof-pipeline:latest <accountNumber>.dkr.ecr.us-east-1.amazonaws.com/edmore/cytof-pipeline:latest

docker push <accountNumber>.dkr.ecr.us-east-1.amazonaws.com/edmore/cytof-pipeline:latest

 aws lambda update-function-code \
      --region us-east-1 \
      --function-name cytof-pipeline \
      --image-uri <accountNumber>.dkr.ecr.us-east-1.amazonaws.com/edmore/cytof-pipeline:latest

```