include .env

.PHONY: build up down restart logs push

build:
	docker compose build

up:
	docker compose up -d

down:
	docker compose down

restart:
	docker compose down && docker compose up -d

logs:
	docker compose logs -f

push:
	docker tag $(IMAGE_NAME) $(DOCKER_REGISTRY)/$(IMAGE_NAME)
	docker push $(DOCKER_REGISTRY)/$(IMAGE_NAME)

remove:
	-docker rmi $(DOCKER_REGISTRY)/$(IMAGE_NAME)	
	-docker rmi $(IMAGE_NAME)