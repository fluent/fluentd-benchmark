#!/bin/bash

rm -f /var/tmp/*.pos
rm -f dummy*.log

rate="$1"
workers="$2"

mkdir -p log

trap "date --rfc-3339=seconds >> log/start-${rate}.timestamp; pkill -f pidstat ;pkill -f dummer; pkill -f fluentd" INT

_rate=$(($rate / $workers))

for n in $(seq $workers);do
    bundle exec dummer -c dummer.conf -o dummy${n}.log -r $_rate &
done

for n in $(seq $workers);do
    bundle exec fluentd -c agent${n}.conf &
done

# wait for running all processes
sleep 5

date --rfc-3339=seconds > log/start-${rate}.timestamp
pidstat -l -G "ruby|fluentd|dummer" -dur 1 > log/pidstat-${rate}.log &

wait

