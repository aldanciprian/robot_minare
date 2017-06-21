#!/bin/sh

#. /home/ciprian/.bashrc
BASE=/media/sf_shared/temp/nicehash_mining/robot_minare/
res=0
startup=0

ctrl_c()
{
	echo "MASTER_PROCESS Trapped CTRL-C"
	if [ $res -ne 0 ]
	then 
		echo "Killing $res"
		kill -9 $res
		res=0
	fi
	exit 0
}

trap ctrl_c INT

while [ 1 ]
do
	echo "===========MASTER_PROCESS  $$============="
	cd $BASE/
	Startup=$(cat control.txt | grep location | awk -F"=" '{print $2}')
	echo ${Startup}
	if [  ${Startup} = "office" ]
	then
		if false 
		then
			ps -ef | grep simpleNiceHash.pl | grep -v grep
			res=$(ps -ef | grep  simpleNiceHash.pl | grep -v grep | grep -v "vi ")
			if [ $? -ne 0 ]
			then
				./simpleNiceHash.pl &
				res=$(ps -ef | grep  simpleNiceHash.pl | grep -v grep | grep -v "vi " |  awk '{print $2}' )
				echo "Starting simpleNiceHash.pl $res"
			else
				res=$(echo $res | awk '{print $2}')
				echo "simpleNiceHash.pl allready started $res"
			fi
		else
			echo "Disabled"
		fi
	else
		if [ $res -ne 0 ]
		then 
			echo "Killing $res"
			kill -9 $res
			res=0
		fi
	fi

	sleep 2s
done
