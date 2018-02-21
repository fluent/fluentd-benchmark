#!/bin/bash

log() {
    echo "$(date --rfc-3339=seconds) ${1}"
}

start_kafka() {
    log "start kafka"
    gcloud compute --project "fluentd-benchmark" ssh --zone "asia-northeast1-a" "kafka" \
           --command "cd ./kafka_2.11-1.0.0 && ./run.sh start"
}

stop_kafka() {
    log "stop kafka"
    gcloud compute --project "fluentd-benchmark" ssh --zone "asia-northeast1-a" "kafka" \
           --command "pkill -SIGKILL -f java"
}

start_sending_metrics() {
    log "start sending metrics"
    pid=$(gcloud compute --project "fluentd-benchmark" ssh --zone "asia-northeast1-a" "kafka" \
                 --command "pgrep -f FluentdSource")
    log "  kafka: pid=$pid"
    gcloud compute --project "fluentd-benchmark" ssh --zone "asia-northeast1-a" "kafka" \
           --command "./send-metrics.rb --host metrics --port 24224 --pid ${pid} --tag kafka-connect-metrics --daemon"
    pid=$(gcloud compute --project "fluentd-benchmark" ssh --zone "asia-northeast1-a" "server" \
                 --command "pgrep -f ascii-8bit")
    log "  server: pid=$pid"
    gcloud compute --project "fluentd-benchmark" ssh --zone "asia-northeast1-a" "server" \
           --command "./send-metrics.rb --host metrics --port 24224 --pid ${pid} --tag fluentd-metrics --daemon"
}

stop_sending_metrics() {
    log "stop sending metrics"
    gcloud compute --project "fluentd-benchmark" ssh --zone "asia-northeast1-a" "kafka" \
           --command "pkill -f send-metrics.rb"
    gcloud compute --project "fluentd-benchmark" ssh --zone "asia-northeast1-a" "server" \
           --command "pkill -f send-metrics.rb"
}

prepare_kafka() {
    log "prepare kafka"
    n_workers=$1
    pushd ansible
    ansible-playbook -i hosts -l kafka -t properties -e "fluentd_worker_pool_size=${n_workers}" playbook.yaml
    popd
}

prepare_server_kafka() {
    log "prepare_server_kafka"
    max_buffer_size=$1
    n_workers=$2
    pushd ansible
    ansible-playbook -i hosts -l server -t td-agent \
                     -e "td_agent_target=kafka" \
                     -e "kafka_max_buffer_size=${max_buffer_size}" \
                     -e "fluentd_workers=${n_workers}" \
                     playbook.yaml
    popd
}

prepare_server_kafka_buffered() {
    log "prepare_server_kafka"
    kafka_agg_max_bytes=$1
    pushd ansible
    ansible-playbook -i hosts -l server -t td-agent \
                     -e "td_agent_target=kafka_buffered" \
                     -e "kafka_agg_max_bytes=${kafka_agg_max_bytes}" \
                     -e "fluentd_workers=${n_workers}" \
                     playbook.yaml
    popd
}

prepare_server_kafka2() {
    log "prepare_server_kafka"
    pushd ansible
    ansible-playbook -i hosts -l server -t td-agent \
                     -e "td_agent_target=kafka2" \
                     -e "fluentd_workers=${n_workers}" \
                     playbook.yaml
    popd
}

run_benchmark() {
    host=$1
    port=24224
    n_events=$2
    period=$3
    log "run benchmark ${host}:${port} ${n_events} events/sec ${period}"
    gcloud compute --project "fluentd-benchmark" ssh --zone "asia-northeast1-a" "client1" \
           --command "./run-benchmark.sh ${host} ${port} ${n_events} ${period}"
}

kafka_connect() {
    n_workers=$1
    log "kafka connect worker=${n_workers}"
    for n in 1000 10000 50000 100000 200000 300000; do
        prepare_kafka $n_workers
        start_kafka
        start_sending_metrics
        log "start kafka connect worker=${n_workers} $n" | tee -a benchmark.log
        run_benchmark kafka $n 5m
        sleep 60
        log "end kafka connect worker=${n_workers} $n" | tee -a benchmark.log
        stop_sending_metrics
        stop_kafka
        sleep 60
    done
}

# NOTE: buffer overflow when 100000
out_kafka() {
    log "out_kafka"
    max_buffer_size=$1
    n_workers=$2
    prepare_server_kafka $max_buffer_size $n_workers
    for n in 1000 10000 50000 100000; do
        start_kafka
        start_sending_metrics
        log "start out_kafka max_buffer_size=${max_buffer_size} worker=${n_workers} $n" | tee -a benchmark.log
        run_benchmark server $n 5m
        sleep 60
        log "end out_kafka max_buffer_size=${max_buffer_size} worker=${n_workers} $n" | tee -a benchmark.log
        stop_sending_metrics
        stop_kafka
        sleep 60
    done
}

# NOTE: buffer overflow when 300000
out_kafka_buffered() {
    log "out_kafka_buffered"
    kafka_agg_max_bytes=$1
    n_workers=$2
    prepare_server_kafka_buffered $kafka_agg_max_bytes $n_workers
    for n in 1000 10000 50000 100000 200000 300000; do
        start_kafka
        start_sending_metrics
        log "start out_kafka_buffered kafka_agg_max_bytes=${kafka_agg_max_bytes} worker=${n_workers} $n" | tee -a benchmark.log
        run_benchmark server $n 5m
        sleep 60
        log "end out_kafka_buffered kafka_agg_max_bytes=${kafka_agg_max_bytes} worker=${n_workers} $n" | tee -a benchmark.log
        stop_sending_metrics
        stop_kafka
        sleep 60
    done
}


# NOTE: buffer overflow when 300000
out_kafka2() {
    log "out_kafka2"
    n_workers=$1
    prepare_server_kafka2 $n_workers
    for n in 1000 10000 50000 100000 200000 300000; do
        start_kafka
        start_sending_metrics
        log "start out_kafka2 worker=${n_workers} $n" | tee -a benchmark.log
        run_benchmark server $n 5m
        sleep 60
        log "end out_kafka2 worker=${n_workers} $n" | tee -a benchmark.log
        stop_sending_metrics
        stop_kafka
        sleep 60
    done
}

stop_sending_metrics
stop_kafka

kafka_connect 1 # default
kafka_connect 2
kafka_connect 4

out_kafka 1000 1 # default
# out_kafka 10000 2
# out_kafka 10000 4
# out_kafka 50000 1

out_kafka_buffered 4k 1 # default
# out_kafka_buffered 100k 2
# out_kafka_buffered 100k 4
# out_kafka_buffered 1m 1

out_kafka2 1
# out_kafka2 2
# out_kafka2 4

