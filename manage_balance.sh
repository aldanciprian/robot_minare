#!/bin/sh -x

while [ 1 ]
do
	PID_OUT=`ps -ef | grep balance.pl | grep -v grep`
	# echo ${PID_OUT}
	if [ $? -eq 0 ]
	then
		#found one
		PID=`echo ${PID_OUT} | awk '{print $2}'`
		echo "balance pid is ${PID}"
	else
		./balance.pl 3291751
		
	fi
	sleep 10s
done
