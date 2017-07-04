#!/usr/bin/perl
#
use strict;
use warnings;
my $interval = 0; #seconds
# my $dump_date = `date  +"%Y_%m_%d_%H_%M_%S"`;
#print $dump_date;
# chomp($dump_date);
# my $dump_date_log = $dump_date."_log.txt";

my $filename = 'monitor_ether_miningpoolhub_log.txt';
open(my $fh, '>>', $filename) or die "Could not open file '$filename' $!";
#while (1)
{
	my @etherscan_output = `lynx -connect_timeout=10 -dump https://etherscan.io/blocks`;
	# `lynx -connect_timeout=5 -dump https://etherscan.io/blocks > ./monitor_ether_dump/$dump_date_log`;
	my $start_print = 0;
	foreach (@etherscan_output)
	{
		if ( $start_print == 1)
		{
			#we are in the table
			#we can search for a correct line
			if ( $_ =~ m/\s*\[.*?\](\d*).*miningpoolhub_1.*/ )
			{
				# nanopool found
				# get the timestamp and the nr of uncles
				my $block_id = $1;
				#print "$_";
				print $fh "$_ ";
				sleep 1;
				my @etherscan_output_block = `lynx -connect_timeout=10 -dump https://etherscan.io/block/$block_id`;
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
						print $fh "$date#";
					}
					if ( $line =~ m/.*Uncles Reward.*/  )
					{
						chomp $line;
						print $line."\t#\t";
						my $nb_uncles = 0;			
						if ( $line =~ /.*\((\d*?) Uncle.*?at.*/ )
						{			
							$nb_uncles = $1;
						}
						#print $fh "$line#";
						print $fh "$nb_uncles#";
						last;
					}
				}
				print $block_id."\n";
				print $fh "$block_id \n";

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
	#sleep $interval;
}
close $fh;
