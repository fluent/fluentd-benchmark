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
bundle exec fluentd -c <CONFIG>.conf
```

`<CONFIG>` are specified as follows:

|                          | type                          |
|--------------------------|-------------------------------|
| agent.conf               | out\_kafka w/o TLS            |
| agent\_buffered.conf     | out\_kakfa\_buffered w/o TLS  |
| agent2.conf              | out\_kakfa2 w/o TLS           |
| agent-tls.conf           | out\_kafka w/ TLS             |
| agent\_buffered-tls.conf | out\_kakfa\_buffered w/ TLS   |
| agent2-tls.conf          | out\_kakfa2 w/ TLS            |

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

### w/o TLS

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
| 10                          | 2.2     |             |                      |
| 100                         | 3.4     |             |                      |
| 1000                        | 13.1    |             |                      |
| 10000                       | 43.7    |             |                      |
| 100000                      | N/A     |             | MAX (buffer overflow)|
| 200000                      | N/A     |             |                      |
| 300000                      |         |             |                      |
| 400000                      |         |             |                      |
| 5247047                     |         |             | MAX of dummer tool   |

For out\_kafka\_buffered

|                             | Total   |             |                      |
|-----------------------------|---------|-------------|----------------------|
| rate of writing (lines/sec) | CPU (%) | Memory (kB) | Remarks              |
| 10                          | 0.5     |             |                      |
| 100                         | 0.9     |             |                      |
| 1000                        | 3.0     |             |                      |
| 10000                       | 33.3    |             |                      |
| 30000                       | 84.1    |             |                      |
| 50000                       | 86.6    |             |                      |
| 80000                       | 90.1    |             |                      |
| 100000                      | 93.1    |             |                      |
| 200000                      | 100.0   |             |                      |
| 300000                      | N/A     |             | MAX (buffer overflow)|
| 400000                      |         |             |                      |
| 5247047                     |         |             | MAX of dummer tool   |

For out_kafka2

|                             | Total   |             |                                 |
|-----------------------------|---------|-------------|---------------------------------|
| rate of writing (lines/sec) | CPU (%) | Memory (kB) | Remarks                         |
| 10                          | 1.0     |             |                                 |
| 100                         | 1.9     |             |                                 |
| 1000                        | 9.3     |             |                                 |
| 10000                       | 33.8    |             |                                 |
| 100000                      | 100.0   |             |                                 |
| 200000                      | 100.0   |             |                                 |
| 300000                      | N/A     |             | MAX (buffer overflow)           |
| 400000                      |         |             |                                 |
| 5247047                     |         |             | MAX of dummer tool              |

### w/ TLS

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
| 10                          | 3.8     |             |                      |
| 100                         | 4.0     |             |                      |
| 1000                        | 8.5     |             |                      |
| 10000                       | 37.3    |             |                      |
| 100000                      | N/A     |             | MAX (buffer Overflow)|
| 200000                      | N/A     |             |                      |
| 300000                      |         |             |                      |
| 400000                      |         |             |                      |
| 5247047                     |         |             | MAX of dummer tool   |

For out\_kafka\_buffered

|                             | Total   |             |                      |
|-----------------------------|---------|-------------|----------------------|
| rate of writing (lines/sec) | CPU (%) | Memory (kB) | Remarks              |
| 10                          | 1.0     |             |                      |
| 100                         | 2.0     |             |                      |
| 1000                        | 8.4     |             |                      |
| 10000                       | 43.8    |             |                      |
| 100000                      | 95.8    |             |                      |
| 200000                      | 100.0   |             |  dummer I/O limit?   |
| 300000                      | N/A     |             |                      |
| 400000                      | N/A     |             |                      |
| 5247047                     |         |             | MAX of dummer tool   |

For out_kafka2

|                             | Total   |             |                                 |
|-----------------------------|---------|-------------|---------------------------------|
| rate of writing (lines/sec) | CPU (%) | Memory (kB) | Remarks                         |
| 10                          | 1.0     |             |                                 |
| 100                         | 1.8     |             |                                 |
| 1000                        | 8.0     |             |                                 |
| 10000                       | 93.5    |             |                                 |
| 20000                       | 90.2    |             |                                 |
| 100000                      | 100.0   |             |                                 |
| 200000                      | 100.0   |             |  dummer I/O limit?              |
| 200000                      | N/A     |             |                                 |
| 300000                      |         |             |                                 |
| 400000                      |         |             |                                 |
| 5247047                     |         |             | MAX of dummer tool              |
