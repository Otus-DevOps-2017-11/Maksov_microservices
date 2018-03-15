USER_NAME ?= maksov
VERSION ?= latest
DIR_MICROSERCVICES ?= src
DIR_MONITORING ?= monitoring

.PHONY: build-all build-comment build-post build-prometheus build-blackbox-exporter buidl-grafana push-grafana push-ui push-comment push-post push-prometheus push-blackbox-exporter push-all start stop

build-comment:
	cd src/comment && bash docker_build.sh

build-post:
	cd src/post && bash docker_build.sh

build-ui:
	cd src/ui && bash docker_build.sh


build-prometheus:
	docker build -t $(USER_NAME)/prometheus:$(VERSION) monitoring/prometheus


build-blackbox-exporter:
	docker build -t $(USER_NAME)/blackbox_exporter:$(VERSION) monitoring/blackbox

build-grafana:
	docker build -t $(USER_NAME)/grafana:$(VERSION) monitoring/grafana

build-all: build-comment build-post build-ui build-prometheus build-blackbox-exporter build-grafana
	

push-ui:
	docker push $(USER_NAME)/ui:$(VERSION)


push-comment:
	docker push $(USER_NAME)/comment:$(VERSION)


push-post:
	docker push $(USER_NAME)/post:$(VERSION)


push-prometheus:
	docker push $(USER_NAME)/proemtheus:$(VERSION)


push-blackbox-exporter:
	docker push $(USER_NAME)/blackbox_exporter:$(VERSION)


push-grafana:
	docker push $(USER_NAME)/grafana:$(VERSION)


push-all: push-ui push-comment push-post push-proemtheus push-blackbox-exporter


start:
	cd docker && docker-compose up -d


stop:
	cd docker && docker-compose down






