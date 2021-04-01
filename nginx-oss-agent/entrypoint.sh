#!/bin/bash

# Get environment variable from docker-compose file
# Or uncomment below
# COMPASS_PROTOCOL=grpc
# COMPASS_SERVER=nginx-instance-manager
# COMPASS_PORT=10443

# turn on job control
set -m
# Check nginx-manager before starting nginx-agent
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
# Start the primary process and put it in the background
/usr/sbin/nginx &
# Start the helper process
/usr/sbin/nginx-agent
# the my_helper_process might need to know how to wait on the
# primary process to start before it does its work and returns  
# now we bring the primary process back into the foreground
# and leave it there
fg %1