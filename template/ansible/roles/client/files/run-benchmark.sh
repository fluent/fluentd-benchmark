#! /bin/bash

cd ~/fluent-benchmark-client/build/install/fluent-benchmark-client

host=$1
port=$2
n_events=$3
period=$4

run_benchmark() {
    ./bin/fluent-benchmark-client \
        --host=$host \
        --port=$port \
        --max-buffer-size=4g \
        --flush-interval=10 \
        --n-events-per-sec=$1 \
        --period=$2
}

echo "$(date) ${host}:${port} ${n_events} events/sec ${period} start" >> benchmark.log
run_benchmark $n_events $period
echo "$(date) ${host}:${port} ${n_events} events/sec ${period} end" >> benchmark.log

