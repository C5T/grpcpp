#!/bin/bash

# NOTE(dkorolev): This script should be run from the top-level directory of the `grpcpp` repo.

echo -e '\033[1m\033[34m=== SERVER ===\033[0m'
echo

echo -ne '\033[1mStarting the server:\033[0m '
SERVER_CONTAINER_ID=$(GRPCPP_MODE=daemon ./grpcpp.sh examples/perftest/sync/server examples/perftest/sync/proto --http_server 5556)

echo $SERVER_CONTAINER_ID

RETVAL=1
function cleanup_and_exit()
{
  if [ "$RETVAL" != "0" ] ; then
    echo
    echo
    echo -n "Stopping the server container ..."
    docker stop -t 0 $SERVER_CONTAINER_ID 2>&1 >/dev/null
    echo -e "\b\b\b\b: Done."
    echo
    exit $RETVAL
  fi
}

trap cleanup_and_exit SIGINT SIGTERM SIGQUIT

echo
echo -e '\033[1m\033[35m=== WAITING ===\033[0m'
echo

STATUS=waiting
for i in $(seq 3000) ; do
  RESULT=$(curl localhost:5556 2>/dev/null)
  if [ "$RESULT" == "OK" ] ; then
    STATUS=up
    break
  fi
  sleep 0.1
done

if [ "$STATUS" != "up" ] ; then
  echo "The server did not start."
  cleanup_and_exit
fi
echo "The server is up."
echo

./grpcpp.sh examples/perftest/sync/perftest examples/perftest/sync/proto --intervals 1

echo -ne '\033[1mStats:\033[0m '
curl localhost:5556/stats 2>/dev/null

echo -ne '\033[1mKill switch:\033[0m '
curl localhost:5556/kill 2>/dev/null

echo -ne '\033[1mDocker stop:\033[0m '
docker stop -t 0 $SERVER_CONTAINER_ID

echo
echo -e '\033[1m\033[36m=== TEST COMPLETE ===\033[0m'
echo

RETVAL=0
