# Fluentd benchmark - kafka-connect-fluentd (source)

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

Use following scripts.

1. https://github.com/okumin/influent/blob/master/bin/generate-ca.sh
1. https://github.com/okumin/influent/blob/master/bin/generate-server-keystore.sh

generate-ca.sh uses openssl command to generate private key and certificate for Fluentd.
generate-server-keystore.sh uses keytool and generate jks format keystore file for influent.

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

----

Use following command to measure client CPU usage and memory usage.

```
pidstat -l -G "fluentd|dummer" -dur 1
```

Use following command to measure server CPU usage and memory usage.

```
pidstat -G "java" -dur 1
```

Client PCs:

1st:

```
CPU: Intel(R) Core(TM) i7-4790K CPU @ 4.00GHz (4cores 8threads)
Memory: 32GB
Disk: HDD
```

2nd:

```
CPU: Intel(R) Core(TM) i7-7700T CPU @ 2.90GHz (4cores 8threads)
Memory: 16GB
Disk: SSD
```

3rd:

```
CPU: Intel(R) Core(TM) i7-3770 CPU @ 3.40GHz (4cores 8threads)
Memory: 16GB
Disk: HDD
```

### w/o TLS

Using `KAFKA_HEAP_OPTS=-Xmx24G`.

| rate of writing (lines/sec) | client processes | Client CPU (%) | Client Memory (KB) | Server CPU(%) | Server Memory (KB) | Remarks                                                    |
|-----------------------------|------------------|----------------|--------------------|---------------|--------------------|------------------------------------------------------------|
|                          10 |                1 |           0.51 |            2558052 |         < 1.0 |           30893472 |                                                            |
|                         100 |                1 |           0.49 |            2558352 |           1.0 |           30962084 |                                                            |
|                        1000 |                1 |           1.08 |            2558448 |           3.0 |           30962084 |                                                            |
|                       10000 |                1 |           7.77 |            2565704 |           8.5 |           30962084 |                                                            |
|                      100000 |                1 |          71.43 |            2576056 |          80.0 |           30962084 |                                                            |
|                      200000 |                2 |         175.80 |            5161933 |           100 |           30962084 |                                                            |
|                      300000 |                3 |         280.78 |            7774361 |           100 |           30962084 |                                                            |
|                      400000 |                4 |            N/A |                N/A |           100 |           30962084 | 1st 300k lines/sec, 2nd 100k lines/sec                     |
|                      500000 |                5 |            N/A |                N/A |           100 |           30962084 | 1st 300k lines/sec, 2nd 100k lines/sec, 3rd 100k lines/sec |

NOTE:
In case of 400k lines/sec and 500k lines/sec results are not accurate.
Because we cannot send just 400k lines/sec and 500k lines/sec in order to client performance limitation.

### w/o TLS maximum throughput

Using `KAFKA_HEAP_OPTS=-Xmx24G`.

NOTE: Fluency can send a lot of records. Limit against worker pool size

| worker pool size | processing (records/sec) | Remarks               |
|------------------|--------------------------|-----------------------|
|                1 |                   534150 |                       |
|                2 |                   803017 |                       |
|                4 |                   916141 | overflow(client side) |
|                8 |                  1135218 | maybe kafka limit     |

Create large log file using dummer and read it from Java program and
send it to kafka-connect-fluentd using Fluency.

### w/ TLS

Using `KAFKA_HEAP_OPTS=-Xmx24G`.

| rate of writing (lines/sec) | client processes | Client CPU (%) | Client Memory (KB) | Server CPU(%) | Server Memory (KB) | Remarks                                                            |
|-----------------------------|------------------|----------------|--------------------|---------------|--------------------|--------------------------------------------------------------------|
|                          10 |                1 |           0.51 |            2558052 |          5.60 |           30899808 |                                                                    |
|                         100 |                1 |           0.62 |            2558448 |          5.88 |           30966372 |                                                                    |
|                        1000 |                1 |           1.33 |            2558408 |          7.39 |           30966372 |                                                                    |
|                       10000 |                1 |           8.40 |            2565604 |         22.05 |           30966372 |                                                                    |
|                      100000 |                1 |          75.64 |            2579636 |         97.03 |           30966372 |                                                                    |
|                      200000 |                2 |         192.12 |            5162172 |           100 |           30968420 |                                                                    |
|                      300000 |                3 |         262.65 |            7971965 |           100 |           30968420 | Buffer overflow(client). Server can process about 200k records/sec |
|                      400000 |                  |                |                    |           N/A |                    | N/A                                                                |
|                      500000 |                  |                |                    |           N/A |                    | N/A                                                                |

