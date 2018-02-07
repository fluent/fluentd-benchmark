#!/bin/bash

start() {
  rm -rf /tmp/zookeeper
  rm -rf /tmp/kafka-logs
  ./bin/zookeeper-server-start.sh -daemon ./config/zookeeper.properties
  ./bin/kafka-server-start.sh -daemon ./config/server.properties
  sleep 10
  KAFKA_HEAP_OPTS="-Xmx4G -Xms4G" ./bin/connect-standalone.sh -daemon \
                 config/connect-standalone.properties \
                 config/FluentdSourceConnector.properties
}

stop() {
  pkill -f FluentdSourceConnector
  ./bin/kafka-server-stop.sh
  ./bin/zookeeper-server-stop.sh
}

trap stop INT TERM

command=$1
$command

