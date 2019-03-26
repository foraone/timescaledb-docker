NAME=timescaledb
ORG=foraone
PG_VER=pg11
PG_VER_NUMBER=$(shell echo $(PG_VER) | cut -c3-)
VERSION=$(shell awk '/^ENV TIMESCALEDB_VERSION/ {print $$3}' Dockerfile)
ARCH=$(shell uname -m | tr '[:upper:]' '[:lower:]' )
BUILD_ARCH=$(ARCH)

ifeq ($(ARCH),aarch64)
    BUILD_ARCH=arm64v8
endif

ifeq ($(ARCH),x86_64)
    BUILD_ARCH=amd64
endif

default: image

.build_$(VERSION)_$(PG_VER)_oss: Dockerfile
	echo 'docker build --build-arg OSS_ONLY=" -DAPACHE_ONLY=1" --build-arg PG_VERSION=$(PG_VER_NUMBER) --build-arg ARCH=$(BUILD_ARCH) -t $(ORG)/$(NAME):latest-$(PG_VER)-$(BUILD_ARCH)-oss .'
	docker build --build-arg OSS_ONLY=" -DAPACHE_ONLY=1" --build-arg PG_VERSION=$(PG_VER_NUMBER) --build-arg ARCH=$(BUILD_ARCH) -t $(ORG)/$(NAME):latest-$(PG_VER)-$(BUILD_ARCH)-oss .
	docker tag $(ORG)/$(NAME):latest-$(PG_VER)-$(BUILD_ARCH)-oss $(ORG)/$(NAME):$(VERSION)-$(PG_VER)-$(BUILD_ARCH)-oss
	touch .build_$(VERSION)_$(PG_VER)_$(BUILD_ARCH)_oss
	docker build --build-arg POSTGIS_VERSION=2.5.1 --build-arg PG_VERSION_TAG=$(PG_VER) -t $(ORG)/$(NAME):latest-$(PG_VER)-$(BUILD_ARCH)-gis-oss ./postgis/
	docker tag $(ORG)/$(NAME):latest-$(PG_VER)-$(BUILD_ARCH)-gis-oss $(ORG)/$(NAME):$(VERSION)-$(BUILD_ARCH)-gis-oss 
	touch .build_postgis_$(VERSION)_$(PG_VER)_$(BUILD_ARCH)_oss

.build_$(VERSION)_$(PG_VER): Dockerfile
	# echo "BUILDING: PG_VERSION=$(PG_VER_NUMBER)"
	# echo "docker build --build-arg PG_VERSION=$(PG_VER_NUMBER) -t $(ORG)/$(NAME):latest-$(PG_VER)-$(BUILD_ARCH) ."
	# docker build --build-arg PG_VERSION=$(PG_VER_NUMBER) -t $(ORG)/$(NAME):latest-$(PG_VER)-$(BUILD_ARCH) .
	# docker tag $(ORG)/$(NAME):latest-$(PG_VER)-$(BUILD_ARCH) $(ORG)/$(NAME):$(VERSION)-$(PG_VER)-$(BUILD_ARCH)
	# touch .build_$(VERSION)_$(PG_VER)_$(BUILD_ARCH)
	docker build --build-arg ARCH=$(BUILD_ARCH) --build-arg POSTGIS_VERSION=2.5.1 --build-arg PG_VERSION_TAG=$(PG_VER) -t $(ORG)/$(NAME):latest-$(PG_VER)-$(BUILD_ARCH)-gis ./postgis/
	docker tag $(ORG)/$(NAME):latest-$(PG_VER)-$(BUILD_ARCH)-gis $(ORG)/$(NAME):$(VERSION)-$(BUILD_ARCH)-gis 
	touch .build_postgis_$(VERSION)_$(PG_VER)_$(BUILD_ARCH)

image: .build_$(VERSION)_$(PG_VER)

oss: .build_$(VERSION)_$(PG_VER)_oss

push: image
	docker push $(ORG)/$(NAME):$(VERSION)-$(PG_VER)-$(BUILD_ARCH)
	docker push $(ORG)/$(NAME):latest-$(PG_VER)-$(BUILD_ARCH)
	docker push $(ORG)/$(NAME):$(VERSION)-$(BUILD_ARCH)-gis
	docker push $(ORG)/$(NAME):latest-$(PG_VER)-$(BUILD_ARCH)-gis

push-oss: oss
	docker push $(ORG)/$(NAME):$(VERSION)-$(PG_VER)-$(BUILD_ARCH)-oss
	docker push $(ORG)/$(NAME):latest-$(PG_VER)-$(BUILD_ARCH)-oss

clean:
	rm -f *~ .build_*

manifest: image
	docker pull $(ORG)/$(NAME):$(VERSION)-amd64-gis
	docker pull $(ORG)/$(NAME):$(VERSION)-arm64v8-gis
	docker manifest create --amend $(ORG)/$(NAME):$(VERSION) $(ORG)/$(NAME):$(VERSION)-amd64-gis $(ORG)/$(NAME):$(VERSION)-arm64v8-gis
	docker manifest create --amend $(ORG)/$(NAME):latest $(ORG)/$(NAME):$(VERSION)-amd64-gis $(ORG)/$(NAME):$(VERSION)-arm64v8-gis
	docker manifest push $(ORG)/$(NAME):$(VERSION)
	docker manifest push $(ORG)/$(NAME):latest

.PHONY: default image push clean
