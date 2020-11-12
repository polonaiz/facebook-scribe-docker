RUNTIME_TAG='polonaiz/facebook-scribe'
RUNTIME_NAME='scribe'

all: build

build:
	docker build . --tag ${RUNTIME_TAG} --squash

clean:
	docker rmi -f ${RUNTIME_TAG}

setup:
	sudo mkdir -p /data/log/scribe/default_primary
	sudo mkdir -p /data/log/scribe/default_secondary
	sudo chown -R ${USER}.${USER} /data/log/scribe

stop:
	docker rm -f ${RUNTIME_NAME}

start:
	docker run \
		--rm \
		--detach \
		--name ${RUNTIME_NAME} \
		--publish 1463:1463 \
		--mount type=bind,source=/mnt/c/data/log/scribe/,destination=/data/log/scribe/,consistency=consistent \
		--mount type=bind,source=$(shell pwd)/default.conf,destination=/etc/scribe/default.conf,consistency=consistent \
		${RUNTIME_TAG}

foreground-start:
	-docker rm -f ${RUNTIME_NAME} && sleep 10
	docker run \
		--rm \
		-t \
		--name ${RUNTIME_NAME} \
		-p 1463:1463 \
		-v /data/log/scribe:/data/log/scribe \
		--mount type=bind,source=$(shell pwd)/default.conf,destination=/etc/scribe/default.conf,consistency=consistent \
		${RUNTIME_TAG}

test:
	docker exec -it ${RUNTIME_NAME} bash -c 'date | scribe_cat test; sleep 1'
	tail /data/log/scribe/default_primary/test/test_current

push:
	docker login
	docker push ${RUNTIME_TAG}
