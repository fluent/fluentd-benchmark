# Fluentd benchmark - forward

This benchmarks following architecture scenario:

```
  Agent Node                                     Receiver Node
  +-----------------------------------+          +-----------------+
  | +-----------+      +-----------+  |          |  +-----------+  |
  | |           |      |           |  |          |  |           |  |
  | | Log File  +----->|  Fluentd  +--------------->|  Fluentd  |  |
  | |           |      |           |  |          |  |           |  |
  | +-----------+  in_tail ----- out_forward   in_forward  -----+  |
  +-----------------------------------+          +-----------------+
```

## Setup Fluentd Receiver

Assum ruby is installed

```
git clone https://github.com/sonots/fluentd-benchmark
cd fluentd-benchmark/one_forward
bundle
bundle exec fluentd -c receiver.conf
```

## Setup Fluentd Agent

Assume ruby is installed

```
git clone https://github.com/sonots/fluentd-benchmark
cd fluentd-benchmark/one_forward
bundle
bundle exec fluentd -c agent.conf
```

## Run benchmark tool and measure

Run at Fluentd agent server. 

This tool generates a log file to dummy.log and Fluentd agent will read and send data to receiver. 

```
cd fluentd-benchmark/one_forward
bundle exec dummer -c dummer.conf
```

You may increase the rate (messages/sec) of generating log by -r option to benchmark. 

```
bundle exec dummer -c dummer.conf -r 100000
```

You should see an output on Fluentd receiver as following. This will tell you the performance of fluentd processing. 

```
2014-02-20 17:20:55 +0900 [info]: plugin:out_flowcounter_simple count:500       indicator:num   unit:second
2014-02-20 17:20:56 +0900 [info]: plugin:out_flowcounter_simple count:500       indicator:num   unit:second
2014-02-20 17:20:57 +0900 [info]: plugin:out_flowcounter_simple count:500       indicator:num   unit:second
```

You may use `iostat -dkxt 1`, `vmstat 1`, `top -c`, `free`, or `dstat` commands to measure system resources. 

## Sample Result

This is a sample result running on my environement


Machine Spec

```
CPU	Xeon E5-2670 2.60GHz x 2 (32 Cores)
Memory	24G
Disk	300G(10000rpm) x 2 [SAS-HDD]
OS CentOS release 6.2 (Final)
```

Result


| rate of writing (lines/sec) | reading (lines/sec)   | CPU (%) | Memory (kB) | Remarks |
|-----------------------------|-----------------------|---------|-------------|---------|
| 10                          | 10                    | 0.2     | 29304       |         |
| 100                         | 100                   | 0.3     | 35812       |         |
| 1000                        | 1000                  | 1.3     | 37864       |         |
| 10000                       | 10000                 | 6.6     | 39912       |         |
| 100000                      | 100000                | 62      | 39912       |         |
| 200000                      | 157148                | 100.4   | 36280       | MAX     |
| 300000                      | N/A                   |         |             |         |
| 400000                      | N/A                   |         |             |         |
| 5247047                     | N/A                   |         |             | MAX of dummer tool        |

