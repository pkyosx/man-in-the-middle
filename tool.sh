
#!/bin/bash -ex

CMD=${1}


if [ "$CMD" == "GEN_CERT" -a "$#" == "1" ]; then
	pushd config
	openssl req -x509 -newkey rsa:4096 -sha256 -nodes -keyout key.pem -out cert.pem -days 360
	popd
elif [ "$CMD" == "DEV_UP" -a "$#" == "1" ]; then
	docker-compose up -d --force-recreate --build
elif [ "$CMD" == "DEV_DOWN" -a "$#" == "1" ]; then
	docker-compose down
else
	echo "Invalid command"
    exit 1
fi