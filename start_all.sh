#!/bin/sh

#. /home/ciprian/.bashrc
BASE=/media/sf_shared/temp/nicehash_mining/robot_minare/
pid=0
startup=0

ctrl_c()
{
	echo "GENESIS Trapped CTRL-C"
	if [ $pid -ne 0 ]
	then 
		#send a trap first
		kill -2 $pid 2>/dev/null
		sleep 1
		echo "Killing $pid"
		kill -9 $pid 2>/dev/null
		pid=0
	fi
	exit 0
}

trap ctrl_c INT

while [ 1 ]
do
	echo "============GENESIS $$============"
	date
	cd $BASE/
	git pull
	Startup=$(cat control.txt | grep startup | awk -F"=" '{print $2}')
	echo ${Startup}
	if [  ${Startup} = "on" ]
	then
		pid=$(ps -ef | grep master_process.sh | grep -v grep)
		if [ $? -ne 0 ]
		then
			echo "master process is not started"
			./master_process.sh &
			pid=$(ps -ef | grep master_process.sh | grep -v grep | awk '{print $2}')
		else
			echo "master process is allready started"
			pid=$(echo $pid | awk '{print $2}')
		fi
	else
		echo "Off"
		if [ $pid -ne 0 ]
		then 
			echo "Killing $pid"
			kill -9 $pid
			pid=0
		fi
	fi

	sleep 10s
done
