all:
	docker buildx build --progress=plain --pull --tag mumblevoip/mumble-server:0 .


test-up:
	docker run --rm -it \
             --name mumble-server \
             --publish 64738:64738/tcp \
             --publish 64738:64738/udp \
             mumblevoip/mumble-server:0