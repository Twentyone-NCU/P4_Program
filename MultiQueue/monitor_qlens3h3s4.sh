#!/bin/bash

CLI_PATH=/usr/local/bin/simple_switch_CLI

#get current unix time in milliseconds
prev_time=`date +%s%N | cut -b1-13`


while true; do
  #qlen1=`echo register_read qdepth 1 | $CLI_PATH --thrift-port 9092 | grep qdepth | awk '{print $3}'`
  qlen2=`echo register_read qdepth 6 | $CLI_PATH --thrift-port 9092 | grep qdepth | awk '{print $3}'`
  qlen3=`echo register_read qdepth 3 | $CLI_PATH --thrift-port 9092 | grep qdepth | awk '{print $3}'`
  

        

  now=`date +%s%N | cut -b1-13` 
  time=$(echo "scale=2; ($now -  $prev_time) / 1000.0"| bc -l)
  echo "H3_S3: "$time"sec" $qlen2"packet" >> s3_h3 &
  echo "S3_S4: " $time"sec" $qlen3"packet" >> s3_s4 &
  sleep 1
done
