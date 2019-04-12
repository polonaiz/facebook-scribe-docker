all: build

build:
	docker build . --tag 'facebook-scribe-docker'

clean:
	docker rmi -f 'facebook-scribe-docker'

stop:
	docker rm -f 'scribe'

start:
	mkdir -p /data/log/scribe/
	mkdir -p /data/log/scribe/default_primary
	mkdir -p /data/log/scribe/default_secondary
	docker run \
		--rm \
		--detach \
		--name 'scribe' \
		--publish 1463:1463 \
		--mount type=bind,source=/data/log/scribe/,destination=/data/log/scribe/,consistency=consistent \
		facebook-scribe-docker

test:
	docker exec -it scribe bash -c 'date | scribe_cat test; sleep 1'
	tail /data/log/scribe/default_primary/test/test_current
