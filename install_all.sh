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
  [ -f ${TMP}/nginx.conf ] && cp -f ${TMP}/nginx.conf ${NGINX_CONF}
  service overpass stop 2>&1 >/dev/null
  [ -f /etc/init.d/overpass ] && rm -f /etc/init.d/overpass
  [ -d /etc/overpass ] && rm -rf /etc/overpass
}

function installNginx {
  if service --status-all 2>&1 | grep -Fq 'nginx'; then
    [ -f ${NGINX_CONF} ] && cp -f ${NGINX_CONF} ${TMP}/nginx.conf
    [ -f ./src/nginx.conf ] && [ -f ${NGINX_CONF} ] && cp -f ./src/nginx.conf ${NGINX_CONF}
    service nginx restart 2>&1 >/dev/null || (echo "NGINX Restart failed!" && exit 2);
  fi
}

function installOverpassAPI {
  ./src/install ${EXEC_DIR} || (echo "Overpass Installation failed!" && exit 4)
  [ ! -d DB_DIR ] && mkdir -p 744 ${DB_DIR}
}

function installOverpassServer {
  cp -f ./src/overpass /etc/init.d/overpass
  mkdir -p -m 744 /etc/overpass && cp ./src/conf.sh /etc/overpass/
  service overpass start 2>&1 >/dev/null || (echo "Overpass Start failed!" && exit 3);
}

echo "Installing components"

installOverpassAPI && installNginx && installOverpassServer

echo "Removing temporary files"

rm -rf ${TMP}

echo "Finished installation"

service fcgiwrap start
service overpass start
service nginx start