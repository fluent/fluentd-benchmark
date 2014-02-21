# Fluentd benchmark - one deliver

This benchmarks following architecture scenario:

() denotes the number of processes. [] denotes the number of threads.

```
  Agent Node                                         Deliver Node                    Receiver Node          
  +----------------------------------------+         +-------------------------+     +---------------------+
  | +-----------+      +----------------+  |         |  +-------------------+  |     |  +---------------+  |
  | |           |      |                |  |         |  |                   |  |     |  |               |  |
  | | Log File  +----->|  Fluentd (15)  +-------------->|  Fluentd [15]     |  +------->|  Fluentd (15) |  |
  | |           |      |                |  |         |  |                   |  |     |  |               |  |
  | +-----------+  in_tail ---------- out_forward  in_forward  ------- out_forward  in_forward  --------+  |
  +----------------------------------------+         +-------------------------+     +---------------------+
```

## Setup Fluentd Receiver

Assum ruby is installed

```
git clone https://github.com/sonots/fluentd-benchmark
cd fluentd-benchmark/one_deliver
bundle
bundle exec fluentd -c receiver.conf
```

This runs 15 processes.

## Setup Fluentd Deliver

Assum ruby is installed

```
git clone https://github.com/sonots/fluentd-benchmark
cd fluentd-benchmark/one_deliver
bundle
bundle exec fluentd -c deliver.conf
```

This receives inputs from agent by one process, and sends to receivers with 15 threads.

## Setup Fluentd Agent

Assume ruby is installed

```
git clone https://github.com/sonots/fluentd-benchmark
cd fluentd-benchmark/one_deliver
bundle
bundle exec fluentd -c agent.conf
```

This runs 15 processes.


## Run benchmark tool and measure

Run at Fluentd agent server. 

This tool generates a log file to /var/log/dummy.log and Fluentd agent will read and send data to receiver. 

```
cd fluentd-benchmark/one_deliver
bundle exec dummer -c dummer.conf
```

You may increase the rate (messages/sec) of generating log by -r option to benchmark. 

```
bundle exec dummer -c dummer.conf -r 1000
```

You should see an output on Fluentd **deliver** as following. This will tell you the performance of fluentd processing. 

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

Result

|                             |                         | Deliver  |             |                       |
|-----------------------------|-------------------------|----------|-------------|-----------------------|
| rate of writing (lines/sec) | receiving (lines / sec) | CPU (%)  | Memory (kB) | Remarks               |
| 10                          | 150                     |          |             |                       |
| 100                         | 1500                    |          |             |                       |
| 1000                        | 15000                   |          |             |                       |
| 10000                       | 150000                  |          |             |                       |
| 20000                       | 306495                  |          |             |                       |
| 30000                       | 338207                  | 100%     |             |                       |
| 100000                      | N/A                     |          |             |                       |

Worse than [multi_agent_forward](../multi_agent_forward) whose receiver simply receives and discards. 

I also tested with one thread deliver and one process receiver, but the result was same. 
