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

plan-state:
	docker-compose run app-deploy -cmd plan-state

apply-state:
	docker-compose run app-deploy -cmd apply-state	

create-backend:
	plan-state
	apply-state

remove-backend:
	docker-compose run app-deploy -cmd destroy-state	

create:
	docker-compose run app-deploy -cmd plan
	docker-compose run app-deploy -cmd apply

destroy:
	docker-compose run app-deploy -cmd destroy

status:
	docker-compose run app-deploy -cmd plan
	docker-compose run app-deploy -cmd output
	docker-compose run app-deploy -cmd graph

apply:
	docker-compose run app-deploy -cmd apply

create-route:
	docker-compose run app-deploy -cmd plan-route
	docker-compose run app-deploy -cmd apply-route	

deploy:
	aws ecr get-login-password --profile ${AWS_PROFILE} --region ${REGION} | docker login --username AWS --password-stdin ${ACCOUNT}.dkr.ecr.${REGION}.amazonaws.com
	@echo "Deploying app"
	cd $(WORKING_DIR)/terraform/application-wrapper/applications ; git clone ${SOURCE_CODE_REPO} app
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
	docker tag pennsieve/app-wrapper ${ACCOUNT}.dkr.ecr.${REGION}.amazonaws.com/${APP_REPO_NAME}
	docker push ${ACCOUNT}.dkr.ecr.${REGION}.amazonaws.com/${APP_REPO_NAME}
	@echo "Deploying post processor"
	cd $(WORKING_DIR)/terraform/post-processor; docker buildx build --platform linux/amd64 --progress=plain -t pennsieve/post-processor .
	docker tag pennsieve/post-processor ${ACCOUNT}.dkr.ecr.${REGION}.amazonaws.com/${POST_PROCESSOR_REPO_NAME}
	docker push ${ACCOUNT}.dkr.ecr.${REGION}.amazonaws.com/${POST_PROCESSOR_REPO_NAME}
	cd $(WORKING_DIR) ; git clean -f ; git checkout -- .
