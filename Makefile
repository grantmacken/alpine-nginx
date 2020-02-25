SHELL=/bin/bash
include .env

ifndef GITHUB_ACTION
LUAJIT_OPT :='-msse4a'
endif
LAST_ALPINE_VER != grep -oP '^FROM alpine:\K[\d\.]+' Dockerfile | head -1


.PHONY: build
build: bld
	@export DOCKER_BUILDKIT=1;
	@docker buildx build -o type=docker \
  --tag $(DOCKER_IMAGE):min-$(NGINX_VER) \
  --tag docker.pkg.github.com/$(REPO_OWNER)/$(REPO_NAME)/$(PROXY_CONTAINER_NAME):$(PROXY_VER) \
  --build-arg PREFIX='$(NGINX_HOME)' \
  --build-arg NGINX_VER='$(NGINX_VER)' \
  --build-arg ZLIB_VER='$(ZLIB_VER)' \
  --build-arg PCRE_VER='$(PCRE_VER)' \
  --build-arg OPENSSL_VER='$(OPENSSL_VER)' \
 .

.PHONY: bld
bld:
	@export DOCKER_BUILDKIT=1;
	@echo '$(DOCKER_IMAGE)'
	@export DOCKER_BUILDKIT=1;
	@echo 'LAST ALPINE VERSION: $(LAST_ALPINE_VER) '
	@if [[ '$(LAST_ALPINE_VER)' = '$(FROM_ALPINE_TAG)' ]] ; then \
 echo 'FROM_ALPINE_TAG: $(FROM_ALPINE_TAG) ' ; else \
 echo ' - updating Dockerfile to Alpine tag: $(FROM_ALPINE_TAG) ' && \
 sed -i 's/alpine:$(LAST_ALPINE_VER)/alpine:$(FROM_ALPINE_TAG)/g' Dockerfile && \
 docker pull alpine:$(FROM_ALPINE_TAG) ; fi
	@docker buildx build -o type=docker \
  --target=bld \
  --tag='$(DOCKER_IMAGE):$(@)-$(NGINX_VER)' \
  --build-arg PREFIX='$(NGINX_HOME)' \
  --build-arg NGINX_VER='$(NGINX_VER)' \
  --build-arg ZLIB_VER='$(ZLIB_VER)' \
  --build-arg PCRE_VER='$(PCRE_VER)' \
  --build-arg OPENSSL_VER='$(OPENSSL_VER)' \
 .

dkrStatus != docker ps --filter name=orMin --format 'status: {{.Status}}'
dkrPortInUse != docker ps --format '{{.Ports}}' | grep -oP '^(.+):\K(\d{4})' | grep -oP "80"
dkrNetworkInUse != docker network list --format '{{.Name}}' | grep -oP "$(NETWORK)"

.PHONY: run
run:
	@$(if $(dkrNetworkInUse),echo  '- NETWORK [ $(NETWORK) ] is available',docker network create $(NETWORK))
	@$(if $(dkrPortInUse), echo '- PORT [ 80 ] is already taken';false , echo  '- PORT [ 80 ] is available')
	@docker run  --rm \
  --name min \
  --publish 80:80 \
  --network $(NETWORK) \
  --detach \
  docker.pkg.github.com/$(REPO_OWNER)/$(REPO_NAME)/$(PROXY_CONTAINER_NAME):$(PROXY_VER)
	@sleep 3
	@docker ps
	@docker logs min

.PHONY: stop
stop:
	@docker stop min
