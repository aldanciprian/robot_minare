#!/usr/bin/perl
#
use strict;
use warnings;
my $interval = 0; #seconds
#while (1)
{
	my @etherscan_output = `lynx -dump https://etherscan.io/blocks`;
	my $start_print = 0;
	foreach (@etherscan_output)
	{
		if ( $start_print == 1)
		{
			#we are in the table
			#we can search for a correct line
			if ( $_ =~ m/\s*\[.*?\](\d*).*Nanopool.*/ )
			{
				# nanopool found
				# get the timestamp and the nr of uncles
				my $block_id = $1;
				#print "$_";
				my @etherscan_output_block = `lynx -dump https://etherscan.io/block/$block_id`;
				foreach my $line (@etherscan_output_block)
				{
					if ( $line =~ m/.*TimeStamp.*\((.*?)\)/  )
					{
						my $date;
						#print "[$line]";
						chomp $line;
						$date = `date --date="$1" +"%Y-%m-%d_%H-%M-%S"`;
						chomp $date;
						print $date."\t#\t";
					}
					if ( $line =~ m/.*Uncles Reward.*/  )
					{
						chomp $line;
						print $line."\t#\t";
						last;
					}
				}
				print $block_id."\n";

			}
		}
		if ( $_ =~ m/Height Age txn Uncles Miner GasLimit/ )
		{
			$start_print = 1;
		}
		if ( $_ =~ m/Etherscan is a Block Explorer and Analytics Platform/ )
		{
			$start_print = 0;
		}
	}
	sleep $interval;
}
