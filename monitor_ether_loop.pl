#!/usr/bin/perl
#
use strict;
use warnings;

use LWP::Simple;                # From CPAN
use JSON qw( decode_json );     # From CPAN
use Data::Dumper;               # Perl core module
use Time::localtime;
use Time::Piece;

my $interval = 13; #seconds
# my $dump_date = `date  +"%Y_%m_%d_%H_%M_%S"`;
#print $dump_date;
# chomp($dump_date);
# my $dump_date_log = $dump_date."_log.txt";
sub net_hastrate_dificulty;
sub timestamp;

my $filename = 'monitor_ether_loop_log.txt';
open(my $fh, '>>', $filename) or die "Could not open file '$filename' $!";
while (1)
{
	my $hashrate;
	my $dificulty;
	my $tstmp = timestamp();
	($hashrate,$dificulty) = net_hastrate_dificulty();
	# print "Test $hashrate $dificulty\n";
	chomp($hashrate);
	$hashrate =~ s/,//;
	$hashrate = $hashrate * 1000;
	$dificulty =~ s/,//;
	# $hashrate = $hashrate * 1000;

	
	print "$tstmp $hashrate ___ $dificulty \n";
	print $fh "$tstmp $hashrate ___ $dificulty \n";
	my @etherscan_output = `lynx -connect_timeout=15 -dump https://etherscan.io/blocks`;
	# `lynx -connect_timeout=5 -dump https://etherscan.io/blocks > ./monitor_ether_dump/$dump_date_log`;
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
				print $fh "$_";
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
close $fh;


sub net_hastrate_dificulty
{
	my @return_value;
	my @etherscan_output = `lynx -connect_timeout=15 -dump https://etherscan.io`;
	foreach (@etherscan_output)
	{
			#we are in the table
			#we can search for a correct line
			#69,513.28 GH/s  1,302.61 TH
			#print "$_";
			if ( $_ =~ m/\s*(\S*?) GH\/s\s*(\S*?) TH.*?/ )
			{		
				# print "$1 $2 \n";
				push (@return_value,$1);
				push (@return_value,$2);
				return @return_value;
			}
	}
}


sub timestamp {
  my $t = localtime;
  return sprintf( "%04d-%02d-%02d_%02d-%02d-%02d",
                  $t->year, $t->mon, $t->mday,
                  $t->hour, $t->min, $t->sec );
}
