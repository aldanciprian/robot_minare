#!/usr/bin/perl
#
use strict;
use warnings;
my $interval = 13; #seconds
# my $dump_date = `date  +"%Y_%m_%d_%H_%M_%S"`;
#print $dump_date;
# chomp($dump_date);
# my $dump_date_log = $dump_date."_log.txt";

my $filename = 'monitor_ether_loop_bw_log.txt';

my $page_index;
my $page="https://etherscan.io/blocks?p=";

sub read_parse;
sub loop;

open(my $fh, '>>', $filename) or die "Could not open file '$filename' $!";

# for ($page_index = 0; $page_index <=500 ; $page_index++)
# {
	# read_parse($page_index);
	# sleep 1;
# }

loop();

close $fh;

sub loop
{
	while (1)
	{
		my @etherscan_output = `lynx -connect_timeout=15 -dump https://etherscan.io/blocks`;
		# `lynx -connect_timeout=5 -dump https://etherscan.io/blocks > ./monitor_ether_dump/$dump_date_log`;
		my $start_print = 0;
		my $blockid = 0;
		foreach (@etherscan_output)
		{
			#print "$_";
			if ( $start_print == 1)
			{
				#print "$_";
				#we are in the table
				#we can search for a correct line
				if ( $_ =~ m/\s*\[.*?\](\d*?) .*/ )
				{
					$blockid = $1;
					#print "$blockid \n";
				}
				if ( $_ =~ m/\s*\[.*?\]0xc0ea08a2d404d3172d2add29a45be56da40e2949.*/ )
				{
					# bw found
					# get the timestamp and the nr of uncles
					my $block_id = $blockid;
					#print "$block_id $_";
					#print $fh "$block_id $_ ";
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
			if ( $_ =~ m/.*Height Age txn Uncles Miner GasLimit.*/ )
			{
				#print "start print \n";
				$start_print = 1;
			}
			if ( $_ =~ m/Etherscan is a Block Explorer and Analytics Platform/ )
			{
				$start_print = 0;
			}
		}
		sleep $interval;
	}
}





sub read_parse
{
	my $index = shift;
	print "lynx -connect_timeout=15 -dump $page$index\n";
	my @etherscan_output = `lynx -connect_timeout=15 -dump $page$index`;
	# `lynx -connect_timeout=5 -dump https://etherscan.io/blocks > ./monitor_ether_dump/$dump_date_log`;
	my $start_print = 0;
	my $blockid = 0;
	foreach (@etherscan_output)
	{
		#print "$_";
		if ( $start_print == 1)
		{
			#print "$_";
			#we are in the table
			#we can search for a correct line
			if ( $_ =~ m/\s*\[.*?\](\d*?) .*/ )
			{
				$blockid = $1;
				#print "$blockid \n";
			}
			if ( $_ =~ m/\s*\[.*?\]0xc0ea08a2d404d3172d2add29a45be56da40e2949.*/ )
			{
				# bw found
				# get the timestamp and the nr of uncles
				my $block_id = $blockid;
				#print "$block_id $_";
				#print $fh "$block_id $_ ";
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
		if ( $_ =~ m/.*Height Age txn Uncles Miner GasLimit.*/ )
		{
			#print "start print \n";
			$start_print = 1;
		}
		if ( $_ =~ m/Etherscan is a Block Explorer and Analytics Platform/ )
		{
			$start_print = 0;
		}
	}
}