.PHONY: help create destroy status apply build

SERVICE_NAME  ?= "app-deploy"
WORKING_DIR   ?= "$(shell pwd)"

.DEFAULT: help

help:
	@echo "Make Help for $(SERVICE_NAME)"
	@echo ""
	@echo "make build			- build relevant images and push to the cloud"
	@echo "make create			- create infrastructure"
	@echo "make destroy			- destroy insfrastructure"
	@echo "make status			- check insfrastructure status"

deploy:
	docker-compose run app-deploy -cmd plan
	docker-compose run app-deploy -cmd apply

destroy:
	docker-compose run app-deploy -cmd destroy

status:
	docker-compose run app-deploy -cmd plan

apply:
	docker-compose run app-deploy -cmd apply

build:
	cd $(WORKING_DIR)/terraform/application-wrapper
	docker build --file Dockerfile_arm64 --progress=plain -t pennsieve/app-wrapper .
