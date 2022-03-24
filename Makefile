RUNTIME_TAG='polonaiz/facebook-scribe'
RUNTIME_NAME='scribe'

all: build

build:
	docker build . --tag ${RUNTIME_TAG}

build-no-cache:
	docker build . --tag ${RUNTIME_TAG} \
		--no-cache

clean:
	docker rmi -f ${RUNTIME_TAG}

push:
	docker login
	docker push ${RUNTIME_TAG}

setup:
	sudo mkdir -p /data/lib/scribe/default_primary
	sudo mkdir -p /data/lib/scribe/default_secondary
	sudo chown -R ${USER}.${USER} /data/log/scribe

start:
	docker run \
		--rm \
		--detach \
		--name ${RUNTIME_NAME} \
		--publish 1463:1463 \
		--mount type=bind,source=/data/lib/scribe/,destination=/data/lib/scribe/,consistency=consistent \
		--mount type=bind,source=$(shell pwd)/default.conf,destination=/etc/scribe/default.conf,consistency=consistent \
		${RUNTIME_TAG}

stop:
	docker rm -f ${RUNTIME_NAME}

test:
	docker exec -it ${RUNTIME_NAME} bash -c 'date | scribe_cat test; sleep 1'
	tail /data/lib/scribe/default_primary/test/test_current

foreground-start:
	-docker rm -f ${RUNTIME_NAME} && sleep 10
	docker run \
		--rm \
		--tty \
		--name ${RUNTIME_NAME} \
		--publish 1463:1463 \
		--mount type=bind,source=/data/lib/scribe/,destination=/data/lib/scribe/,consistency=consistent \
		--mount type=bind,source=$(shell pwd)/default.conf,destination=/etc/scribe/default.conf,consistency=consistent \
		${RUNTIME_TAG}

kube-install:
	kubectl config current-context
	kubectl apply -f ./kubernetes.resource.d/scribe.yaml

kube-tail-test:
	kubectl exec scribe-656475dd78-n4d7n -it -- tail -F /data/lib/scribe/default_primary/test/test_current

kube-delete:
	kubectl delete service scribe
	kubectl delete deployments.apps scribe
	kubectl delete pvc scribe-data-pvc

kube-install-tester:
	kubectl apply -f ./kubernetes.resource.d/tester.pod.yaml

kube-test-tester:
	kubectl exec scribe-tester -it -- bash -c 'echo -------- | scribe_cat -h scribe test'
	kubectl exec scribe-tester -it -- bash -c 'date | scribe_cat -h scribe test'
	kubectl exec scribe-tester -it -- bash -c 'hostname | scribe_cat -h scribe test'

kube-delete-tester:
	kubectl delete pod scribe-tester
