#!/bin/sh -x

while [ 1 ]
do
	PID_OUT=`ps -ef | grep control_order_mixt.pl | grep -v grep`
	# echo ${PID_OUT}
	if [ $? -eq 0 ]
	then
		#found one
		PID=`echo ${PID_OUT} | awk '{print $2}'`
		echo "control order mixt  pid is ${PID}"
	else
		# ./control_order_mixt.pl 3291751
		
		 ./control_order_spikes.pl 3291751	
	fi
	sleep 5s
done
