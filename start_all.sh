#!/bin/sh


BASE=/media/sf_shared/temp/nicehash_mining/robot_minare/
res=0
startup=0
while [ 1 ]
do
	echo "========================"
	date
	cd $BASE/
	git pull
	Startup=$(cat control.txt | grep startup | awk -F"=" '{print $2}')
	echo ${Startup}
	if [  ${Startup} = "on" ]
	then
		Startup=$(cat control.txt | grep location | awk -F"=" '{print $2}')
		echo ${Startup}
		if [  ${Startup} = "office" ]
		then
			res=$(ps -ef | grep  simpleNiceHash.pl | grep -v grep )
			if [ $? -ne 0 ]
			then
				echo "Starting simpleNiceHash.pl"
				./simpleNiceHash.pl &
				res=$(ps -ef | grep  simpleNiceHash.pl | grep -v grep | awk '{print $2}' )
			else
				res=$(echo $res | awk '{print $2}')
				echo "simpleNiceHash.pl allready started $res"
			fi
		else
			if [ $res -ne 0 ]
			then 
				echo "Killing $res"
				kill -9 $res
				res=0
			fi
		fi
	else
		echo "Off"
		if [ $res -ne 0 ]
		then 
			echo "Killing $res"
			kill -9 $res
			res=0
		fi
	fi

	sleep 2s
done
