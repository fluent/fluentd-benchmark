#!/bin/bash

rm -f /var/tmp/*.pos
rm -f dummy*.log
mkdir -p log

rate="$1"
workers="$2"

trap "date --rfc-3339=seconds >> log/start-tls-${rate}.timestamp; pkill -f dummer; pkill -f fluentd" INT

_rate=$(($rate / $workers))

for n in $(seq $workers);do
    bundle exec dummer -c dummer.conf -o dummy${n}.log -r $_rate &
done

for n in $(seq $workers);do
    bundle exec fluentd -c agent-tls${n}.conf &
done

sleep 5

date --rfc-3339=seconds > log/start-tls-${rate}.timestamp
pidstat -l -G "fluentd|dummer" -dur 1 > log/pidstat-${rate}.log &

wait

