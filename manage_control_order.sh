#!/bin/sh -x

while [ 1 ]
do
	PID_OUT=`ps -ef | grep control_order.pl | grep -v grep`
	# echo ${PID_OUT}
	if [ $? -eq 0 ]
	then
		#found one
		PID=`echo ${PID_OUT} | awk '{print $2}'`
		echo "control order pid is ${PID}"
	else
		./control_order.pl 3104143
	fi
	sleep 5s
done
