#!/bin/sh

blocks=$(for i in ` cat monitor_ether_loop_log.txt  | grep 2017 | sort |  uniq  | awk -F"#" '{print $1}'` ; do echo $i 1 0 0 0 0 ; done )

mining=$(cat control_order_spikes_log.txt | grep 2017 | grep -v TimeStamp | sed "s/08-/07-/g" | awk '{print $1" 0 "$3" "$5" "$11" 0"}')

balance=$(./format_balance_log.pl  | sed "s/3917-/2017-/g" | sed "s/08-/07-/g" | sort | uniq | grep "2017" | awk '{print $1" 0 0 0 0 "$3}' )


# echo "$balance"
echo "${blocks}"  > /tmp/file.txt
echo "${mining}"  >> /tmp/file.txt
echo "${balance}"  >> /tmp/file.txt

cat /tmp/file.txt | sort

