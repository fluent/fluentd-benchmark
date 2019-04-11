fluentd-benchmark
=================

Benchmark collection of Fluentd use cases.

For the simplest usecase, have a look at [one_forward](./one_forward) first.

Provided benchmarks
-------------------

| Testcase            | Purpose                                  |
| ------------------- | ---------------------------------------- |
| in_forward          | Measure forwarding input rate            |
| kafka-connect       | Measure Kafka rate                       |
| keep_forward        | Measure rate with keepalive              |
| one_forward         | Measure rate with single forwarder       |
| out_forward         | Measure forwarding output rate           |
| out_kafka           | Measure various output rates to Kafka    |
| peer_deliver        | Measure multi-receiver (separate) rate   |
| round_robin_deliver | Measure multi-receiver (integrated) rate |

docker-compose testing
----------------------

For the usecases with Kafka or Keepalive a Docker Compose based test setup is
provided, consisting of a YAML-based Docker Compose description and
`benchmark.sh` wrapping it.

You would run it like this:

```
git clone https://github.com/fluent/fluentd-benchmark
cd fluentd-benchmark
./benchmark.sh one_forward
```

Please note that this does _not_ use your current checked out version, but the
`master` from https://github.com/fluent/fluentd-benchmark - adjust as needed.

This wrapper expects Docker Compose, GNU sed, GNU head and
https://github.com/nferraz/st to be installed

(MacOS: `brew install coreutils docker-compose gnu-sed st`)
