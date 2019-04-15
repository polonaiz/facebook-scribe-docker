all: build

build:
	docker build . --tag 'polonaiz/facebook-scribe' --squash

clean:
	docker rmi -f 'polonaiz/facebook-scribe'

stop:
	docker rm -f 'scribe'

start:
	mkdir -p /data/log/scribe/default_primary
	mkdir -p /data/log/scribe/default_secondary
	docker run \
		--rm \
		--detach \
		--name 'scribe' \
		--publish 1463:1463 \
		--mount type=bind,source=/data/log/scribe/,destination=/data/log/scribe/,consistency=consistent \
		polonaiz/facebook-scribe

test:
	docker exec -it scribe bash -c 'date | scribe_cat test; sleep 1'
	tail /data/log/scribe/default_primary/test/test_current

push:
	docker login
	docker push polonaiz/facebook-scribe
