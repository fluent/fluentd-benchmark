#!/bin/bash

SED="sed"
HEAD="head"
DURATION=120

[ "$(uname -s)" == "Darwin" ] && SED=gsed
[ "$(uname -s)" == "Darwin" ] && HEAD=ghead

BENCHMARK_NAME="$1"
if [ -f "${BENCHMARK_NAME}/docker-compose.yml" ]; then
  DOCKER_COMPOSE_YML="${BENCHMARK_NAME}/docker-compose.yml"
else
  DOCKER_COMPOSE_YML=""
fi

# if we're done, clean up all child processes
if [ -z "${DOCKER_COMPOSE_YML}" ] ; then
  echo Usage:
  echo
  echo "  $0 testsuite"
  echo
  echo Available testsuites:
  echo
  ls */docker-compose.yml | $SED -e 's,/docker-compose.yml$,,' | sort
  exit 1
fi

exithandler() {
  docker-compose -f "${DOCKER_COMPOSE_YML}" down
  kill 0 # all child processes
}
trap exithandler EXIT

echo Starting docker containers ...

docker-compose -f "${DOCKER_COMPOSE_YML}" build
docker-compose -f "${DOCKER_COMPOSE_YML}" up > "${BENCHMARK_NAME}.out" 2> "${BENCHMARK_NAME}.err" &
tail -qf "${BENCHMARK_NAME}.out" "${BENCHMARK_NAME}.err" &

echo Waiting for events to start flowing ...

WAIT=1200
while ! grep >/dev/null out_flowcounter_simple "${BENCHMARK_NAME}.out"; do
  sleep 0.1
  (( WAIT=WAIT-1 ))

  if [ $WAIT -le 0 ]; then
    echo "No events within two minutes :("
    echo
    exit 1
  fi
done
echo Events are flowing, collecting data for "${DURATION}s" ...

sleep "${DURATION}"

echo Time is up, shutting down emitter ...
docker-compose -f "${DOCKER_COMPOSE_YML}" exec agent bash -c 'kill $(pidof bundle)'

sleep 2

echo Shutting down all other containers ...
docker-compose -f "${DOCKER_COMPOSE_YML}" down

echo Benchmark done. Preparing results ...

# extract counts and ignore the first and last lines, which contain incomplete counts
grep out_flowcounter_simple "${BENCHMARK_NAME}.out" | \
  $SED -e 's/.*count:\([0-9]\+\).*/\1/' | \
  tail -n +2 | \
  $HEAD -n -2 | \
  st --transpose-output --n --min --max --mean --median
