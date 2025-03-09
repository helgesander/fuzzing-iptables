HOST_UID = $(shell id -u)
HOST_GID = $(shell id -g)
CONTAINER_NAME = iptables-fuzzing-lab

.PHONY : all stop build run attach root
all : stop build run

stop:
	-docker stop $(CONTAINER_NAME)
	# sleep 1
	-docker rmi $(CONTAINER_NAME)

build:
	docker build \
	--build-arg HOST_GID=$(HOST_GID) \
	--build-arg HOST_UID=$(HOST_UID) \
	-t $(CONTAINER_NAME) .

run:
	docker run --rm -v $(CURDIR):/pwd --privileged --cap-add=NET_ADMIN --cap-add=SYS_PTRACE --security-opt seccomp=unconfined -d --name $(CONTAINER_NAME) -i $(CONTAINER_NAME)

attach:
	docker exec -it $(CONTAINER_NAME) /bin/bash

root:
	docker exec -u root -it $(CONTAINER_NAME) /bin/bash
