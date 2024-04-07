.PHONY: help create destroy status apply deploy

SERVICE_NAME  ?= "app-deploy"
WORKING_DIR   ?= "$(shell pwd)"

.DEFAULT: help

help:
	@echo "Make Help for $(SERVICE_NAME)"
	@echo ""
	@echo "make create-backend - creates storage for state file"
	@echo "make create - create infrastructure"
	@echo "make deploy - deploy application"
	@echo "make destroy - destroy infrastructure"
	@echo "make status - check infrastructure status and generate graph of infrastructure"

create-backend:
	docker-compose run app-deploy -cmd create-backend

delete-backend:
	docker-compose run app-deploy -cmd delete-backend	

create:
	docker-compose run app-deploy -cmd create

destroy:
	docker-compose run app-deploy -cmd destroy

status:
	docker-compose run app-deploy -cmd status

create-route:
	docker-compose run app-deploy -cmd create-route

delete-route:
	docker-compose run app-deploy -cmd delete-route	

deploy:
	aws ecr get-login-password --profile ${AWS_PROFILE} --region ${AWS_DEFAULT_REGION} | docker login --username AWS --password-stdin ${ACCOUNT}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com
	@echo "Deploying app"
	cd $(WORKING_DIR)/terraform/application-wrapper/applications ; git clone -b ${APP_GIT_BRANCH} --single-branch "https://${APP_GIT_REPOSITORY}" app
	cd $(WORKING_DIR)/terraform/application-wrapper/applications/app ; docker buildx build --platform linux/amd64 --progress=plain -t pennsieve/${APP_NAME} .
	docker tag pennsieve/${APP_NAME} ${APP_REPO}
	docker push ${APP_REPO}
	rm -rf $(WORKING_DIR)/terraform/application-wrapper/applications/app
	@echo "Deploying post processor"
	cd $(WORKING_DIR)/terraform/post-processor; docker buildx build --platform linux/amd64 --progress=plain -t pennsieve/post-processor .
	docker tag pennsieve/post-processor ${POST_PROCESSOR_REPO}
	docker push ${POST_PROCESSOR_REPO}
	@echo "Deploying workflow manager"
	cd $(WORKING_DIR)/terraform/application-wrapper/applications ; git clone -b ${WM_GIT_BRANCH} --single-branch "https://${WM_GIT_REPOSITORY}" app
	cd $(WORKING_DIR)/terraform/application-wrapper/applications/app ; docker buildx build --platform linux/amd64 --progress=plain -t pennsieve/workflow-manager .
	docker tag pennsieve/workflow-manager ${WM_REPO}
	docker push ${WM_REPO}
	rm -rf $(WORKING_DIR)/terraform/application-wrapper/applications/app
	@echo "Deploying pre-processor"
	cd $(WORKING_DIR)/terraform/pre-processor; docker buildx build --platform linux/amd64 --progress=plain -t pennsieve/pre-processor .
	docker tag pennsieve/pre-processor ${PRE_PROCESSOR_REPO}
	docker push ${PRE_PROCESSOR_REPO}
	cd $(WORKING_DIR) ; git clean -f ; git checkout -- .
