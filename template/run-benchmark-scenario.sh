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
           --command "nohup ./send-metrics.rb --host metrics --port 24224 --pid ${pid} --tag kafka-connect-metrics &"
    pid=$(gcloud compute --project "fluentd-benchmark" ssh --zone "asia-northeast1-a" "server" \
                 --command "pgrep -f ascii-8bit")
    log "  server: pid=$pid"
    gcloud compute --project "fluentd-benchmark" ssh --zone "asia-northeast1-a" "server" \
           --command "nohup ./send-metrics.rb --host metrics --port 24224 --pid ${pid} --tag fluentd-metrics &"
}

stop_sending_metrics() {
    log "stop sending metrics"
    gcloud compute --project "fluentd-benchmark" ssh --zone "asia-northeast1-a" "kafka" \
           --command "pkill -f send-metrics.rb"
    gcloud compute --project "fluentd-benchmark" ssh --zone "asia-northeast1-a" "server" \
           --command "pkill -f send-metrics.rb"
}

prepare_server() {
    log "prepare server"
    target=$1
    pushd ansible
    ansible-playbook -i hosts -l server -t td-agent -e "td_agent_target=${target}" playbook.yaml
    popd
}

run_benchmark() {
    host=$1
    port=24224
    n_events=$2
    period=$3
    log "run benchmark ${host}:${port} ${n_events} events/sec ${period}"
    gcloud compute --project "fluentd-benchmark" ssh --zone "asia-northeast1-a" "client1" \
           --command "nohup ./run-benchmark.sh ${host} ${port} ${n_events} ${period} &"
}

kafka_connect() {
    log "kafka connect"
    for n in 1000 10000 50000 100000 200000 300000; do
        start_kafka
        start_sending_metrics
        run_benchmark kafka $n 5m
        stop_sending_metrics
        stop_kafka
        sleep 60
    done
}

# NOTE: buffer overflow when 100000
out_kafka() {
    log "out_kafka"
    prepare_server kafka
    for n in 1000 10000 50000 100000; do
        start_kafka
        start_sending_metrics
        run_benchmark server $n 5m
        stop_sending_metrics
        stop_kafka
        sleep 60
    done
}

# NOTE: buffer overflow when 300000
out_kafka_buffered() {
    log "out_kafka_buffered"
    prepare_server kafka_buffered
    for n in 1000 10000 50000 100000 200000 300000; do
        start_kafka
        start_sending_metrics
        run_benchmark server $n 5m
        stop_sending_metrics
        stop_kafka
        sleep 60
    done
}


# NOTE: buffer overflow when 300000
out_kafka2() {
    log "out_kafka2"
    prepare_server kafka2
    for n in 1000 10000 50000 100000 200000 300000; do
        start_kafka
        start_sending_metrics
        run_benchmark server $n 5m
        stop_sending_metrics
        stop_kafka
        sleep 60
    done
}

stop_sending_metrics
stop_kafka

kafka_connect
out_kafka
out_kafka_buffered
out_kafka2

