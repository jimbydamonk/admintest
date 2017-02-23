.PHONY: build build-static clean test help default

BIN_NAME=admintest

VERSION := $(shell grep "const Version " version.go | sed -E 's/.*"(.+)"$$/\1/')
GIT_COMMIT=$(shell git rev-parse HEAD)
GIT_DIRTY=$(shell test -n "`git status --porcelain`" && echo "+CHANGES" || true)
IMAGE_NAME := "jimbydamonk/admintest"

default: test

help:
	@echo 'Management commands for admintest:'
	@echo
	@echo 'Usage:'
	@echo '    make build           Compile the project.'
	@echo '    make get-deps        runs glide install, mostly used for ci.'
	@echo '    make build-static    Compile static binary.'
	@echo '    make build-docker    Build inside a docker container.'
	@echo '    make run-docker      Runs binary in docker.'
	@echo '    make package         Build final docker image with just the go binary inside'
	@echo '    make tag             Tag image created by package with latest, git commit and version'
	@echo '    make test            Run tests on a compiled project.'
	@echo '    make push            Push tagged images to registry'
	@echo '    make clean           Clean the directory tree.'
	@echo

build: test
	@echo "building ${BIN_NAME} ${VERSION}"
	@echo "GOPATH=${GOPATH}"
	go build -ldflags "-X main.GitCommit=${GIT_COMMIT}${GIT_DIRTY} -X main.VersionPrerelease=DEV" -o bin/${BIN_NAME}

get-deps:
	glide install

build-static:
	@echo "Building static ${BIN_NAME} ${VERSION}"
	go build -ldflags '-w -linkmode external -extldflags "-static" -X main.GitCommit=${GIT_COMMIT}${GIT_DIRTY} -X main.VersionPrerelease=VersionPrerelease=RC' -o bin/${BIN_NAME}

build-docker:
	@echo "Building ${BIN_NAME} ${VERSION} in docker"
	docker build -t admintest:build -f Dockerfile.build .

run-docker: build
	@echo "building ${BIN_NAME} ${VERSION}"
	docker build -t admintest:latest -f Dockerfile .
	docker run --name=admintest -v $(GOPATH):/gopath/  admintest

package: build
	@echo "building image ${BIN_NAME} ${VERSION} $(GIT_COMMIT)"
	docker build --build-arg VERSION=${VERSION} --build-arg GIT_COMMIT=$(GIT_COMMIT) -t $(IMAGE_NAME):local .

tag:
	@echo "Tagging: latest ${VERSION} $(GIT_COMMIT)"
	docker tag $(IMAGE_NAME):local $(IMAGE_NAME):$(GIT_COMMIT)
	docker tag $(IMAGE_NAME):local $(IMAGE_NAME):${VERSION}
	docker tag $(IMAGE_NAME):local $(IMAGE_NAME):latest

push: tag
	@echo "Pushing docker image to registry: latest ${VERSION} $(GIT_COMMIT)"
	docker login -e ${DOCKER_EMAIL -u $DOCKER_USER -p $DOCKER_PASS
	docker push $(IMAGE_NAME):$(GIT_COMMIT)
	docker push $(IMAGE_NAME):${VERSION}
	docker push $(IMAGE_NAME):latest

clean:
	test ! -e bin/${BIN_NAME} || rm bin/${BIN_NAME}
	docker ps -a |grep admintest | awk '{print $$1}' | xargs -rn 1 docker rm > /dev/null 2>&1
	docker images | grep 'admintest' | awk '{print $$3}' | xargs -rn 1 docker rmi > /dev/null 2>&1

test: get-deps
	go test $(glide nv)

