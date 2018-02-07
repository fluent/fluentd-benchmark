#! /bin/bash

cd ~/fluent-benchmark-client/build/install/fluent-benchmark-client

host=$1
port=$2

run_benchmark() {
    echo "Start ${1} $(date)" >> benchmark.log
    ./bin/fluent-benchmark-client \
        --host=$host \
        --port=$port \
        --max-buffer-size=4g \
        --flush-interval=10 \
        --n-events-per-sec=$1 \
        --period=20m
    echo "End ${1} $(date)" >> benchmark.log
    sleep 60
}

run_benchmark 1000
run_benchmark 10000
run_benchmark 100000
run_benchmark 200000
run_benchmark 300000
run_benchmark 400000
run_benchmark 500000
run_benchmark 1000000
