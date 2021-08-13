#!/bin/bash
# turn on bash's job control
set -m

# Start the primary process and put it in the background
/usr/sbin/nginx -g 'daemon off;' &
# start nim
/usr/sbin/nginx-manager &
declare -r HOST="${COMPASS_PROTOCOL}://${COMPASS_SERVER}:${COMPASS_PORT}"
wait-for-url() {
    echo "Testing $1"
    timeout -s TERM ${COMPASS_TIMEOUT} bash -c \
    'while [[ "$(curl -s -k -o /dev/null -L -w ''%{http_code}'' ${0})" != "200" ]];\
    do echo "Waiting for ${0}" && sleep 2;\
    done' ${1}
    echo "OK!"
    curl -I -k "$1"
}
wait-for-url "${HOST}"
echo "$HOSTNAME"
# Start the helper process
/usr/sbin/nginx-agent
# now we bring the primary process back into the foreground
# and leave it there
fg %1