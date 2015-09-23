# Fluentd benchmark - peer deliver

This benchmarks following architecture scenario:

() denotes the number of processes. [] denotes the number of threads.

```
  Agent Node                                         Deliver Node                    Receiver Node
  +----------------------------------------+         +-------------------------+     +---------------------+
  | +-----------+      +----------------+  |         |  +-------------------+  |     |  +---------------+  |
  | |           |      |                |  |         |  |                   |  |     |  |               |  |
  | | Log File  +----->|  Fluentd (10)  +-------------->|  Fluentd (1)[1]   |  +------->|  Fluentd (1)  |  |
  | |           |      |                |  |         |  |                   |  |     |  |               |  |
  | +-----------+  in_tail -------+-- out_forward  in_forward  ------- out_forward  in_forward  --------+  |
  +-------------------------------|--------+         +-------------------------+     +---------------------+
                                  |
                                  |                  +-------------------------+     +---------------------+   
                                  |                  |  +-------------------+  |     |  +---------------+  |
                                  |                  |  |                   |  |     |  |               |  |
                                  +-------------------->|  Fluentd (1)[1]   |  +------->|  Fluentd (1)  |  |
                                                     |  |                   |  |     |  |               |  |
                                                     |  +------------- out_forward  in_forward  --------+  |
                                                     +-------------------------+     +---------------------+
```

So, each deliver process send data to a specific receiver process. 

## Setup Fluentd Receiver

Assume ruby is installed

```
git clone https://github.com/fluent/fluentd-benchmark
cd fluentd-benchmark/peer_deliver
bundle
bundle exec fluentd -c receiver.conf
```

## Setup Fluentd Deliver

Assume ruby is installed

```
git clone https://github.com/fluent/fluentd-benchmark
cd fluentd-benchmark/peer_deliver
bundle
bundle exec fluentd -c deliver.conf
```

## Setup Fluentd Agent

Assume ruby is installed

```
git clone https://github.com/fluent/fluentd-benchmark
cd fluentd-benchmark/peer_deliver
bundle
bundle exec fluentd -c agent.conf
```

## Run benchmark tool and measure

Run at Fluentd agent server. 

This tool outputs logs to `dummy.log`, and Fluentd agent reads it and sends data to receivers. 

```
cd fluentd-benchmark/peer_deliver
bundle exec dummer -c dummer.conf
```

You may increase the rate (messages/sec) of log generation by -r option to benchmark. 

```
bundle exec dummer -c dummer.conf -r 1000
```

You should see an output on Fluentd **deliver** as followings. This tells you the performance of fluentd processing. 

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
Disk    150G(10000rpm) x 2 [SAS-HDD]
OS CentOS release 6.2 (Final)
```

Result: 

Please notice that same log data are copied 10 times because there exists 10 processed agents.

| rate of writing (lines/sec) | receiving (lines / sec / process) | Remarks               |
|-----------------------------|-----------------------------------|-----------------------|
| 10                          | 50                                |                       |
| 100                         | 500                               |                       |
| 1000                        | 5000                              |                       |
| 10000                       | 50000                             |                       |
| 20000                       | 100000                            |                       |
| 50000                       | 250000                            |                       |
| 60000                       | 269636                            | Delay occured         |

Did not change with [round_robin_deliver](../round_robin_deliver). 

Although receiver process should be able to receive 467393 lines / sec at maximum,
the maximum was only 269636 lines / sec per process in this experiment. 
This shows that deliver node disturbs data processing. 

