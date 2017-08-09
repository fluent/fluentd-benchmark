# Fluentd benchmark - kafka-connect-fluentd ()

This benchmarks following architecture scenario:

```
 Agent Node                                     Apache Kafka
  +-----------------------------------+          +--------------------------------+
  | +-----------+      +-----------+  |          |  +-------------------------+   |
  | |           |      |           |  |          |  |                         |   |
  | | Log File  +----->|  Fluentd  +--------------->|  Source                 |   |
  | |           |      |           |  |          |  | (FluentdSourceConnector)|   |
  | +-----------+  in_tail ----- out_forward     |  +-------------------------+   |
  +-----------------------------------+          +--------------------------------+
```

We can increase Agent Node to send a lot of messages to Apache Kafka.

## Setup Fluentd

Assume ruby is installed

```
git clone https://github.com/fluent/fluentd-benchmark
cd fluentd-benchmark/kafka-connect
bundle
bundle exec fluentd -c agent.conf
```

## Setup Kafka

**NOTE:** Assume java and kafka tarball is installed.

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

Run FluentdSourceConnector:

```
env KAFKA_HEAP_OPTS=-Xmx4096M bin/connect-standalone.sh config/connect-standalone.properties FluentdSourceConnector.properties
```

**NOTE** You can set `KAFKA_HEAP_OPTS=-Xmx4096M -Xms4096M` to avoid JVM OOM.

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

You should see an output on FluentdSourceConnector as followings. This tells you the performance of FluentdSourceConnector processing.

```
[2017-08-09 11:19:27,150] INFO 500 requests/sec (org.fluentd.kafka.FluentdSourceTask:45)
[2017-08-09 11:19:28,154] INFO 500 requests/sec (org.fluentd.kafka.FluentdSourceTask:45)
[2017-08-09 11:19:29,155] INFO 500 requests/sec (org.fluentd.kafka.FluentdSourceTask:45)
```

You should see an output on Fluentd receiver as followings. This tells you the performance of fluentd processing.

```
2014-02-20 17:20:55 +0900 [info]: plugin:out_flowcounter_simple count:500       indicator:num   unit:second
2014-02-20 17:20:56 +0900 [info]: plugin:out_flowcounter_simple count:500       indicator:num   unit:second
2014-02-20 17:20:57 +0900 [info]: plugin:out_flowcounter_simple count:500       indicator:num   unit:second
```

You may use `iostat -dkxt 1`, `vmstat 1`, `top -c`, `free`, or `dstat` commands to measure system resources.

## SSL/TLS

TODO: write about key generation

## Sample Result

Machine Spec

```
CPU	Intel(R) Core(TM) i7-6700 CPU @ 3.40GHz (4Cores 8Threads)
Memory	64G
Disk	Crucial　CT1050MX300SSD4 1TB SSD
OS Debian Stretch 9.1 amd64
```

Without TLS

|                             | Total   |             |                                |
|-----------------------------|---------|-------------|--------------------------------|
| rate of writing (lines/sec) | CPU (%) | Memory (kB) | Remarks                        |
| 10                          | 14.3    |             |                                |
| 100                         | 15.5    |             |                                |
| 1000                        | 14.7    |             |                                |
| 10000                       | 17.7    |             |                                |
| 100000                      | 30.4    |             |                                |
| 150000                      | 40.2    |             |                                |
| 250000                      | 48.7    |             | one in_tail reading threashold |
| 300000                      | N/A     |             |                                |
| 400000                      | N/A     |             |                                |
| 500000                      | N/A     |             |                                |
| 5247047                     |         |             | MAX of dummer tool             |

With TLS and `KAFKA_HEAP_OPTS="-Xmx4096M -Xms4096M`"

|                             | Total   |             |                                |
|-----------------------------|---------|-------------|--------------------------------|
| rate of writing (lines/sec) | CPU (%) | Memory (kB) | Remarks                        |
| 10                          | 15.4    |             |                                |
| 100                         | 16.8    |             |                                |
| 1000                        | 15.6    |             |                                |
| 10000                       | 92.1    |             | JVM heap shortage?             |
| 100000                      | 91.8    |             |                                |
| 150000                      | N/A     |             |                                |
| 250000                      | N/A     |             |                                |
| 300000                      | N/A     |             |                                |
| 400000                      | N/A     |             |                                |
| 500000                      | N/A     |             |                                |
| 5247047                     |         |             | MAX of dummer tool             |

With TLS and `KAFKA_HEAP_OPTS="-Xmx24G -Xms24G`"

|                             | Total   |             |                                |
|-----------------------------|---------|-------------|--------------------------------|
| rate of writing (lines/sec) | CPU (%) | Memory (kB) | Remarks                        |
| 10                          | 15.0    |             |                                |
| 100                         | 15.3    |             |                                |
| 1000                        | 17.8    |             |                                |
| 10000                       | 38.0    |             |                                |
| 100000                      | 46.9    |             | dummer I/O limit?              |
| 150000                      | 45.0    |             |                                |
| 250000                      | 47.4    |             |                                |
| 300000                      | 47.9    |             |                                |
| 400000                      | 49.8    |             |                                |
| 500000                      | N/A     |             |                                |
| 5247047                     |         |             | MAX of dummer tool             |
