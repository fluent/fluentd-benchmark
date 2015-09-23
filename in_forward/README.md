# Fluentd benchmark - multi agent forward

The scenario shows the maximum performance of in_forward. 

This benchmarks following architecture scenario:

() denotes the number of processes

```
  Agent Node                                          Receiver Node
  +----------------------------------------+          +--------------------+
  | +-----------+      +----------------+  |          |  +--------------+  |
  | |           |      |                |  |          |  |              |  |
  | | Log File  +----->|  Fluentd (30)  +--------------->|  Fluentd (1) |  |
  | |           |      |                |  |          |  |              |  |
  | +-----------+  in_tail ---------- out_forward   in_forward  --------+  |
  +----------------------------------------+          +---------------------+
```

## Setup Fluentd Receiver

Assume ruby is installed

```
git clone https://github.com/fluent/fluentd-benchmark
cd fluentd-benchmark/in_forward
bundle
bundle exec fluentd -c receiver.conf
```

## Setup Fluentd Agent

Assume ruby is installed

```
git clone https://github.com/fluent/fluentd-benchmark
cd fluentd-benchmark/in_forward
bundle
bundle exec fluentd -c agent.conf
```

This runs 30 agent processes, which reads logs from the same file dummy.log.

## Run benchmark tool and measure

Run at Fluentd agent server. 

This tool outputs logs to `dummy.log`, and Fluentd agent reads it and sends data to a receiver. 

```
cd fluentd-benchmark/in_forward
bundle exec dummer -c dummer.conf
```

You may increase the rate (messages/sec) of log generation -r option to benchmark. 

```
bundle exec dummer -c dummer.conf -r 1000
```

You should see an output on Fluentd receiver as followings. This tells you the performance of fluentd processing. 

```
2014-02-20 17:20:55 +0900 [info]: plugin:out_flowcounter_simple count:30000       indicator:num   unit:second
2014-02-20 17:20:55 +0900 [info]: plugin:out_flowcounter_simple count:30000       indicator:num   unit:second
2014-02-20 17:20:55 +0900 [info]: plugin:out_flowcounter_simple count:30000       indicator:num   unit:second
```

You may use `iostat -dkxt 1`, `vmstat 1`, `top -c`, `free`, or `dstat` commands to measure system resources. 

## Sample Result

This is a sample result running on my environement

Machine Spec

```
CPU Xeon E5-2670 2.60GHz x 2 (32 Cores)
Memory  24G
Disk    300G(10000rpm) x 2 [SAS-HDD]
OS CentOS release 6.2 (Final)
```

Result

|                             |                         | Agent   |             | Receiver |             |                       |
|-----------------------------|-------------------------|---------|-------------|----------|-------------|-----------------------|
| rate of writing (lines/sec) | receiving (lines / sec) | CPU (%) | Memory (kB) | CPU (%)  | Memory (kB) | Remarks               |
| 10                          | 300                     |         |             |          |             |                       |
| 100                         | 3000                    |         |             |          |             |                       |
| 1000                        | 30000                   |         |             |          |             |                       |
| 10000                       | 467393                  |         |             | 100%     | 3435976     | CPU bound at receiver |
| 100000                      | N/A                     |         |             |          |             |                       |
| 150000                      | N/A                     |         |             |          |             |                       |
| 200000                      | N/A                     |         |             |          |             |                       |

