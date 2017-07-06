#!/usr/bin/perl
#

	my @etherscan_output = `cat ./monitor_ether_loop_log.txt  | grep "^\\s*2017" | sort | uniq | awk -F"#" '{print \$1}'`;
	

	foreach (@etherscan_output)
	{
		print $_;
	}
