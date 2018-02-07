# Benchmark fluent-plugin-kafka and kafka-connect-fluentd

## Install

### Install Terraform

See https://www.terraform.io/intro/getting-started/install.html

### Install ansible

See http://docs.ansible.com/ansible/latest/intro_installation.html

### Setup Terraform

```
$ terraform init Terraform/
```

## Create instances

### Run terraform

```
$ terraform apply Terraform/
```

### Prepare for provisioning

Generate SSH key pair at first time.

```
$ gcloud compute --project "fluentd-benchmark" ssh --zone "asia-northeast1-a" "server"  --command "echo"
$ gcloud compute --project "fluentd-benchmark" ssh --zone "asia-northeast1-a" "kafka"   --command "echo"
$ gcloud compute --project "fluentd-benchmark" ssh --zone "asia-northeast1-a" "client1" --command "echo"
$ gcloud compute --project "fluentd-benchmark" ssh --zone "asia-northeast1-a" "metrics" --command "echo"
```

Create ansible/ansible.cfg

```
[ssh_connection]
ssh_args = -o ControlMaster=auto -o ControlPersist=60s -o StrictHostKeyChecking=no -o UserKnownHostsFile=~/.ssh/google_compute_known_hosts
```

### Provision

Generate inventory file for ansible and run ansible-playbook command.

```
$ ./generate-hosts.rb
$ cd ansible
$ ansible-playbook -i hosts playbook.yml
```

Prepare influxdb and grafana.

```
$ gcloud compute --project "fluentd-benchmark" ssh --zone "asia-northeast1-a" "metrics"
metrics $ docker-compose up -d
metrics $ docker-compose exec influxdb influx -execute 'create database "kafka-metrics"'
metrics $ docker-compose exec influxdb influx -execute 'create database "fluentd"'
metrics $ docker-compose exec influxdb influx -execute 'create database "kafka-connect"'
metrics $ docker-compose exec influxdb influx -execute 'show databases'
```

TODO: Add grafana configuration

Run Kafka and kafka-connect-fluentd (FluentdSource).

```
$ gcloud compute --project "fluentd-benchmark" ssh --zone "asia-northeast1-a" "kafka" \
  --command "cd ~/kafka_2.11-1.0.0 && ./run.sh start"
```

Stop Kafka and kafka-connect-fluentd (FluentdSource).

```
$ gcloud compute --project "fluentd-benchmark" ssh --zone "asia-northeast1-a" "kafka" \
  --command "cd ~/kafka_2.11-1.0.0 && ./run.sh stop"
```

## Send metrics

Run send-metrics.rb before run benchmark.

```
$ gcloud compute --project "fluentd-benchmark" ssh --zone "asia-northeast1-a" "kafka" \
  --command "./send-metrics.rb --host metrics --port 24224 --pid PID --tag kafka-connect-metrics"
$ gcloud compute --project "fluentd-benchmark" ssh --zone "asia-northeast1-a" "server" \
  --command "./send-metrics.rb --host metrics --port 24224 --pid PID --tag fluentd-metrics"
```

These command send metrics (CPU usage, memory usage, etc.) to metrics server.

## Run benchmark

For out_kafka, out_kafka_buffered or out_kafka2:

```
$ gcloud compute --project "fluentd-benchmark" ssh --zone "asia-northeast1-a" "client1" \
  --command './run-benchmark.sh server 24224'
```

For kafka-connect-fluentd (FluentdSource):

```
$ gcloud compute --project "fluentd-benchmark" ssh --zone "asia-northeast1-a" "client1" \
  --command './run-benchmark.sh kafka 24224'
```

## Benchmark result

Use port forwarding

```
$ gcloud compute --project "fluentd-benchmark" ssh --zone "asia-northeast1-a" "metrics" \
  -- -L 3000:localhost:3000
```

Access http://localhost:3001 using web browser and login admin/admin.

