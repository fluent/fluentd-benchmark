#!/bin/bash

jps -m > pidstat.log

pidstat -G "ruby" -dur 1 | tee -a pidstat.log

