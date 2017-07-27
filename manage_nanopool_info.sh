#!/bin/sh -x

while [ 1 ]
do
	PID_OUT=`ps -ef | grep nanopool_info.pl | grep -v grep`
	# echo ${PID_OUT}
	if [ $? -eq 0 ]
	then
		#found one
		PID=`echo ${PID_OUT} | awk '{print $2}'`
		echo "nanopool_info is ${PID}"
	else
		./nanopool_info.pl
		
	fi
	sleep 10s
done
