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
	cd $(WORKING_DIR)/terraform/application-wrapper/applications ; git clone "https://${APP_GIT_REPOSITORY}" app
	cd $(WORKING_DIR)/terraform/application-wrapper/applications/app
	cp $(WORKING_DIR)/terraform/application-wrapper/applications/app/${ENTRYPOINT} $(WORKING_DIR)/terraform/application-wrapper/${ENTRYPOINT}
	cp $(WORKING_DIR)/terraform/application-wrapper/applications/app/Dockerfile $(WORKING_DIR)/terraform/application-wrapper/Dockerfile
    ifeq ($(ENTRYPOINT),main.py)
		cp $(WORKING_DIR)/terraform/application-wrapper/main.py.nf $(WORKING_DIR)/terraform/application-wrapper/main.nf
		cp $(WORKING_DIR)/terraform/application-wrapper/applications/app/requirements.txt $(WORKING_DIR)/terraform/application-wrapper/requirements.txt
    else ifeq ($(ENTRYPOINT),main.R)
		cp $(WORKING_DIR)/terraform/application-wrapper/main.R.nf $(WORKING_DIR)/terraform/application-wrapper/main.nf
		cp -R $(WORKING_DIR)/terraform/application-wrapper/applications/app/dependencies/* $(WORKING_DIR)/terraform/application-wrapper/dependencies
    endif
	rm -rf $(WORKING_DIR)/terraform/application-wrapper/applications/app
	cd $(WORKING_DIR)/terraform/application-wrapper; docker buildx build --platform linux/amd64 --progress=plain -t pennsieve/app-wrapper .
	docker tag pennsieve/app-wrapper ${APP_REPO}
	docker push ${APP_REPO}
	@echo "Deploying post processor"
	cd $(WORKING_DIR)/terraform/post-processor; docker buildx build --platform linux/amd64 --progress=plain -t pennsieve/post-processor .
	docker tag pennsieve/post-processor ${POST_PROCESSOR_REPO}
	docker push ${POST_PROCESSOR_REPO}
	cd $(WORKING_DIR) ; git clean -f ; git checkout -- .
