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
	docker build --build-arg OSS_ONLY=" -DAPACHE_ONLY=1" --build-arg PG_VERSION=$(PG_VER_NUMBER) -t $(ORG)/$(NAME):latest-$(PG_VER)-$(BUILD_ARCH)-oss .
	docker tag $(ORG)/$(NAME):latest-$(PG_VER)-$(BUILD_ARCH)-oss $(ORG)/$(NAME):$(VERSION)-$(PG_VER)-$(BUILD_ARCH)-oss
	touch .build_$(VERSION)_$(PG_VER)_$(BUILD_ARCH)_oss

.build_$(VERSION)_$(PG_VER): Dockerfile
	docker build --build-arg PG_VERSION=$(PG_VER_NUMBER) -t $(ORG)/$(NAME):latest-$(PG_VER)-$(BUILD_ARCH) .
ifeq ($(PG_VER),pg9.6)
	docker tag $(ORG)/$(NAME):latest-$(PG_VER)-$(BUILD_ARCH) $(ORG)/$(NAME):latest-$(BUILD_ARCH)
endif
	docker tag $(ORG)/$(NAME):latest-$(PG_VER)-$(BUILD_ARCH) $(ORG)/$(NAME):$(VERSION)-$(PG_VER)-$(BUILD_ARCH)
	touch .build_$(VERSION)_$(PG_VER)_$(BUILD_ARCH)

image: .build_$(VERSION)_$(PG_VER)

oss: .build_$(VERSION)_$(PG_VER)_oss

push: image
	docker push $(ORG)/$(NAME):$(VERSION)-$(PG_VER)-$(BUILD_ARCH)
	docker push $(ORG)/$(NAME):latest-$(PG_VER)-$(BUILD_ARCH)
ifeq ($(PG_VER),pg9.6)
	docker push $(ORG)/$(NAME):latest-$(BUILD_ARCH)
endif

push-oss: oss
	docker push $(ORG)/$(NAME):$(VERSION)-$(PG_VER)-$(BUILD_ARCH)-oss
	docker push $(ORG)/$(NAME):latest-$(PG_VER)-$(BUILD_ARCH)-oss

clean:
	rm -f *~ .build_*

.PHONY: default image push push-oss oss clean
