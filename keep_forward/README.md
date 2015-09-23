# Fluentd benchmark - keep forward

This benchmarks following architecture scenario:

```
  Agent Node                                       Receiver Node
  +-----------------------------------+            +-----------------+
  | +-----------+      +-----------+  |            |  +-----------+  |
  | |           |      |           |  | keepalive  |  |           |  |
  | | Log File  +----->|  Fluentd  +----------------->|  Fluentd  |  |
  | |           |      |           |  |            |  |           |  |
  | +-----------+  in_tail ---- keep_forward   in_forward --------+  |
  +-----------------------------------+            +-----------------+
```

## Setup Fluentd Receiver

Assume ruby is installed

```
git clone https://github.com/fluent/fluentd-benchmark
cd fluentd-benchmark/keep_forward
bundle
bundle exec fluentd -c receiver.conf
```

## Setup Fluentd Agent

Assume ruby is installed

```
git clone https://github.com/fluent/fluentd-benchmark
cd fluentd-benchmark/keep_forward
bundle
bundle exec fluentd -c agent.conf
```

## Run benchmark tool and measure

Run at Fluentd agent server. 

This tool outputs logs to `dummy.log`, and Fluentd agent reads it and sends data to a receiver. 

```
cd fluentd-benchmark/keep_forward
bundle exec dummer -c dummer.conf
```

You may increase the rate (messages/sec) of log generation by -r option to benchmark. 

```
bundle exec dummer -c dummer.conf -r 1000
```

You should see an output on Fluentd receiver as followings. This tells you the performance of fluentd processing. 

```
2014-02-20 17:20:55 +0900 [info]: plugin:out_flowcounter_simple count:1000       indicator:num   unit:second
2014-02-20 17:20:56 +0900 [info]: plugin:out_flowcounter_simple count:1000       indicator:num   unit:second
2014-02-20 17:20:57 +0900 [info]: plugin:out_flowcounter_simple count:1000       indicator:num   unit:second
```

You may use `iostat -dkxt 1`, `vmstat 1`, `top -c`, `free`, or `dstat` commands to measure system resources. 

## Sample Result

This is a sample result running on my environement

Machine Spec

```
CPU Xeon E5-2670 2.60GHz x 2 (30 Cores)
Memory  24G
Disk    300G(10000rpm) x 2 [SAS-HDD]
OS CentOS release 6.2 (Final)
```

Result

| rate of writing (lines/sec) | reading (lines/sec)   | CPU (%) | Memory (kB) | Remarks |
|-----------------------------|-----------------------|---------|-------------|---------|
| 10                          | 10                    |         |             |         |
| 100                         | 100                   |         |             |         |
| 1000                        | 1000                  |         |             |         |
| 10000                       | 10000                 |         |             |         |
| 100000                      | 100000                |         |             |         |
| 200000                      | 153218                |         |             | MAX     |
| 300000                      | N/A                   |         |             |         |
| 400000                      | N/A                   |         |             |         |
| 5247047                     | N/A                   |         |             | MAX of dummer tool        |

Does not change with [one_forward](../out_foward) scenario. 

Keepalive effectively worked only when I set smaller `buffer_chunk_limit` like 100k although I do not put sample results here. 
