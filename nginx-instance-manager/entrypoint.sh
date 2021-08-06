#!/bin/bash
nginx &
nginx-manager &
# gotta put the previous two in background or it won't sleep
sleep 30
nginx-agent
fg %1

