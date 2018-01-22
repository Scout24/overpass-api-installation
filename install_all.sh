#!/bin/bash

set -e

if [[ $EUID > 0 ]]; then
	echo "Run as root!";
	exit 1;
fi

source ./src/conf.sh

TMP=$(mktemp -d -t tmp.XXXXXXXXXX)

NGINX_CONF=/etc/nginx/nginx.conf

function removeIfSomethingBreaks {
  service overpass stop 2>&1 >/dev/null
  [ -f /etc/init.d/overpass ] && rm -f /etc/init.d/overpass
  [ -d /etc/overpass ] && rm -rf /etc/overpass
  rm -rf ${TMP}
}

function installNginx {
  if service --status-all 2>&1 | grep -Fq 'nginx'; then
    install -bm 644 ./src/nginx.conf ${NGINX_CONF}
    service nginx restart || (echo "NGINX Restart failed!" && exit 2);
  fi
}

function installOverpassAPI {
  ./src/install ${EXEC_DIR} || (echo "Overpass Installation failed!" && exit 4)
  [ ! -d ${DB_DIR} ] && mkdir -p 744 ${DB_DIR}
}

function installOverpassServer {
  mkdir -p /etc/init.d && cp ./src/overpass "$_" && chmod 755 "$_"/overpass
  mkdir -p /etc/overpass && cp ./src/conf.sh "$_" && chmod 644 "$_"/conf.sh
  systemctl daemon-reload
  systemctl enable overpass.service
  service overpass start || (echo "Overpass Start failed!" && exit 3);
}

echo "Installing components"

installOverpassAPI && installNginx && installOverpassServer

echo "Removing temporary files"

rm -rf ${TMP}

echo "Finished installation"

service fcgiwrap start
service overpass start
service nginx start