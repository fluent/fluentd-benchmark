#!/bin/bash

jps -m > pidstat.log

pidstat -G "java" -dur 1 | tee -a pidstat.log

