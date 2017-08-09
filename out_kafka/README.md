# Fluentd benchmark - kafka

This benchmarks following architecture scenario:

```
  Agent Node                                     Apache Kafka
  +-----------------------------------+          +-----------------+
  | +-----------+      +-----------+  |          |  +-----------+  |
  | |           |      |           |  |          |  |           |  |
  | | Log File  +----->|  Fluentd  +--------------->|  server   |  |
  | |           |      |           |  |          |  |           |  |
  | +-----------+  in_tail ----- out_kafka       |  +-----------+  |
  +-----------------------------------+          +-----------------+
```

## Setup Fluentd Receiver

Assume ruby is installed

```
git clone https://github.com/fluent/fluentd-benchmark
cd fluentd-benchmark/out_kafka
bundle
bundle exec fluentd -c agent.conf
```

## Setup Kafka

Assume java and kafka tarball is installed
Run zookeeper:

```
cd KAFKA_ROOT
bin/zookeeper-server-start.sh config/zookeeper.properties
```

Run kafka server:

```
cd KAFKA_ROOT
bin/kafka-server-start.sh config/server.properties
```

Create dummy topic:

```
cd KAFKA_ROOT
bin/kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic dummy
```

## Run benchmark tool and measure

Run at Fluentd agent server.

This tool outputs logs to `dummy.log`, and Fluentd agent reads it and sends data to a receiver.

```
cd fluentd-benchmark/out_kafka
bundle exec dummer -c dummer.conf
```

You may increase the rate (messages/sec) of log generation by -r option to benchmark.

```
bundle exec dummer -c dummer.conf -r 100000
```

You should see an output on Fluentd receiver as followings. This tells you the performance of fluentd processing.

```
2014-02-20 17:20:55 +0900 [info]: plugin:out_flowcounter_simple count:500       indicator:num   unit:second
2014-02-20 17:20:56 +0900 [info]: plugin:out_flowcounter_simple count:500       indicator:num   unit:second
2014-02-20 17:20:57 +0900 [info]: plugin:out_flowcounter_simple count:500       indicator:num   unit:second
```

You may use `iostat -dkxt 1`, `vmstat 1`, `top -c`, `free`, or `dstat` commands to measure system resources.

## Sample Result

This is a sample result running on my environment


Machine Spec

```
CPU	Intel(R) Core(TM) i7-6700 CPU @ 3.40GHz (4Cores 8Threads)
Memory	64G
Disk	Crucial　CT1050MX300SSD4 1TB SSD
OS Debian Stretch 9.1 amd64
```

Result

For out_kafka

|                             | Total   |             |                      |
|-----------------------------|---------|-------------|----------------------|
| rate of writing (lines/sec) | CPU (%) | Memory (kB) | Remarks              |
| 10                          | 5.6     |             |                      |
| 100                         | 5.0     |             |                      |
| 1000                        | 6.3     |             |                      |
| 10000                       | 12      |             | MAX (buffer Overflow)|
| 100000                      | N/A     |             |                      |
| 200000                      | N/A     |             |                      |
| 300000                      |         |             |                      |
| 400000                      |         |             |                      |
| 5247047                     |         |             | MAX of dummer tool   |

For out\_kafka\_buffered

|                             | Total   |             |                      |
|-----------------------------|---------|-------------|----------------------|
| rate of writing (lines/sec) | CPU (%) | Memory (kB) | Remarks              |
| 10                          | 5.6     |             |                      |
| 100                         | 5.0     |             |                      |
| 1000                        | 6.3     |             |                      |
| 10000                       | 12      |             |                      |
| 30000                       | 20.2    |             |                      |
| 50000                       | 21.5    |             |                      |
| 80000                       | 21.8    |             |                      |
| 100000                      | N/A     |             | MAX (buffer Overflow)|
| 200000                      | N/A     |             |                      |
| 300000                      |         |             |                      |
| 400000                      |         |             |                      |
| 5247047                     |         |             | MAX of dummer tool   |
