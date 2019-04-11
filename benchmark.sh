#!/bin/bash

SED="sed"
HEAD="head"
DURATION=120

[ "$(uname -s)" == "Darwin" ] && SED=gsed
[ "$(uname -s)" == "Darwin" ] && HEAD=ghead

# if we're done, clean up all child processes
if [ -z "$1" ] || [ ! -f "$1.yml" ]; then
  echo Usage:
  echo
  echo "  $0 testsuite"
  echo 
  echo Available testsuites:
  echo
  find -- * -name \*.yml | $SED -e 's/\.yml$//' | sort
  exit 1
else
  BENCHMARK=$1
fi

exithandler() {
  docker-compose -f "${BENCHMARK}.yml" stop
  kill 0 # all child processes
}
trap exithandler EXIT

echo Starting docker containers ...

docker-compose -f "${BENCHMARK}.yml" up > "${BENCHMARK}.out" 2> "${BENCHMARK}.err" &
tail -qf "${BENCHMARK}.out" "${BENCHMARK}.err" &

echo Waiting for events to start flowing ...

WAIT=1200
while ! grep >/dev/null out_flowcounter_simple "${BENCHMARK}.out"; do
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
docker exec -ti fluentd-benchmark_agent_1 /bin/bash -c 'kill `pidof bundle`'

sleep 2

echo Shutting down all other containers ...
docker-compose -f "${BENCHMARK}.yml" stop

echo Benchmark done. Preparing results ...

# extract counts and ignore the first and last lines, which contain incomplete counts
grep out_flowcounter_simple "${BENCHMARK}.out" | $SED -e 's/.*count:\([0-9]\+\).*/\1/' | tail -n +2 | $HEAD -n -2 | st --transpose-output --n --min --max --mean --median
