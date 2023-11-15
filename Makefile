.PHONY: help create destroy status apply deploy

SERVICE_NAME  ?= "app-deploy"
WORKING_DIR   ?= "$(shell pwd)"

.DEFAULT: help

help:
	@echo "Make Help for $(SERVICE_NAME)"
	@echo ""
	@echo "make create - create infrastructure"
	@echo "make deploy - deploy application"
	@echo "make destroy - destroy infrastructure"
	@echo "make status - check infrastructure status"

create:
	docker-compose run app-deploy -cmd plan
	docker-compose run app-deploy -cmd apply

destroy:
	docker-compose run app-deploy -cmd destroy

status:
	docker-compose run app-deploy -cmd plan

apply:
	docker-compose run app-deploy -cmd apply

deploy:
	@echo "Deploying app"
	cd $(WORKING_DIR)/terraform/application-wrapper; docker buildx build --platform linux/amd64 --progress=plain -t pennsieve/app-wrapper .
	aws ecr get-login-password --profile ${AWS_PROFILE} --region ${REGION} | docker login --username AWS --password-stdin ${ACCOUNT}.dkr.ecr.${REGION}.amazonaws.com
	docker tag pennsieve/app-wrapper ${ACCOUNT}.dkr.ecr.${REGION}.amazonaws.com/${REPO}
	docker push ${ACCOUNT}.dkr.ecr.${REGION}.amazonaws.com/${REPO}

