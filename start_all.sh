#!/bin/sh

while [ 1 ]
do
	echo "started all" > /tmp/$$_$0.log
	ps -ef
	sleep 1s
done
