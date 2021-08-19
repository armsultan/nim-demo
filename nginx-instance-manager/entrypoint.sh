#!/bin/bash
# turn on bash's job control
set -m

# Start nginx and put it in the background
/usr/sbin/nginx -g 'daemon off;' &
# Start NIM before before starting to poll it
/usr/sbin/nginx-manager &

# Poll NIM, looping through a curl until it returns a 200 or times out before starting agent
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
# Start the agent
/usr/sbin/nginx-agent
# Bring nginx into foreground and leave it there
fg %1