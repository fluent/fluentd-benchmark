# Fluentd benchmark - multi receiver forward

This scenario would show the maximum performance of out_forward.

This benchmarks following architecture scenario:

() denotes the number of processes. [] denotes the number of threads.

```
  Agent Node                                          Receiver Node
  +----------------------------------------+          +---------------------+
  | +-----------+      +----------------+  |          |  +---------------+  |
  | |           |      |                |  |          |  |               |  |
  | | Log File  +----->|  Fluentd [30]  +--------------->|  Fluentd (30) |  |
  | |           |      |                |  |          |  |               |  |
  | +-----------+  in_tail ---------- out_forward   in_forward  ---------+  |
  +----------------------------------------+          +---------------------+
```

## Setup Fluentd Receiver

Assume ruby is installed

```
git clone https://github.com/fluent/fluentd-benchmark
cd fluentd-benchmark/out_forward
bundle
bundle exec fluentd -c receiver.conf
```

This runs 30 receiver processes.

## Setup Fluentd Agent

Assume ruby is installed

```
git clone https://github.com/fluent/fluentd-benchmark
cd fluentd-benchmark/out_forward
bundle
bundle exec fluentd -c agent.conf
```

This runs one process, but 30 threads of out_forward.

## Run benchmark tool and measure

Run at Fluentd agent server. 

This tool outputs logs to `dummy.log`, and Fluentd agent reads it and sends data to receivers. 

```
cd fluentd-benchmark/out_forward
bundle exec dummer -c dummer.conf
```

You may increase the rate (messages/sec) of log generation by -r option to benchmark. 

```
bundle exec dummer -c dummer.conf -r 1000
```

You should see an output on Fluentd **agent** as followings. This tells you the performance of fluentd processing. 

```
2014-02-20 17:20:55 +0900 [info]: plugin:out_flowcounter_simple count:1000       indicator:num   unit:second
2014-02-20 17:20:55 +0900 [info]: plugin:out_flowcounter_simple count:1000       indicator:num   unit:second
2014-02-20 17:20:55 +0900 [info]: plugin:out_flowcounter_simple count:1000       indicator:num   unit:second
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
| 10                          | 10                      |         |             |          |             |                       |
| 100                         | 100                     |         |             |          |             |                       |
| 1000                        | 1000                    |         |             |          |             |                       |
| 10000                       | 10000                   |         |             |          |             |                       |
| 100000                      | 87192                   | 100.4   | 51372       |          |             | CPU bound at agent    |
| 150000                      | N/A                     |         |             |          |             |                       |
| 200000                      | N/A                     |         |             |          |             |                       |

This result was worse than [one_forward](../one_forward), which sent 157148 lines / sec at maximum per process. 
So, [one_forward](../one_forward) showed the maximum performance of out_forward (but, it was bounded by receiver process, so...).

