#!/usr/bin/perl 

use LWP::Simple;                # From CPAN
use JSON qw( decode_json );     # From CPAN
use Data::Dumper;               # Perl core module
use strict;                     # Good practice
use warnings;                   # Good practice
use Time::localtime;
use Time::Piece;
use LWP::UserAgent;
use Digest::SHA qw(hmac_sha512_hex);
use Switch;


sub net_hastrate_dificulty;
sub timestamp;
sub get_tstmp;
sub get_hashrate;
sub get_state;

my $file_samplings = "prezicere_samplings.txt";
my $file_samplings_h;
my $file_mine = "prezicere_mining.txt";
my $file_mine_h;


my $win_procent = 0.5;

my $sleep_interval = 10;

my $samplings_size = 240 / $sleep_interval; # 4 minutes of data
my $mine_ctr = 0;
my $mine_ctr_start_delay = 60 / $sleep_interval;
my $mine_ctr_execution = 600 / $sleep_interval;
my $mine_ctr_stop_delay = 60 / $sleep_interval;

my $machine_state = 1; # 1 -searching , 2-delay start , 3-mining , 4 -delay stop

my @samplings;

open $file_samplings_h, $file_samplings or warn "Could not open $file_samplings: $!";
while( my $line = <$file_samplings_h>)  {   
	chomp($line);
	push @samplings, $line;
	$machine_state = get_state($line);	
}
close $file_samplings_h;



while ( 1 )
{
	my $tstmp = timestamp();
	print "TIME is : $tstmp \n";

	net_hastrate_dificulty($machine_state);
	
	switch ($machine_state) {
	case 1 { 

			my $first_tstmp = get_tstmp($samplings[ 0 ]);

			my $last_tstmp = get_tstmp($samplings[ $#samplings - 1]);
			print "first $first_tstmp last $last_tstmp \n";		
			my $firstTime = Time::Piece->strptime($first_tstmp,'%Y-%m-%d_%H-%M-%S');
			my $lastTime = Time::Piece->strptime($last_tstmp,'%Y-%m-%d_%H-%M-%S');
			
			if ( $#samplings < ($samplings_size - 1) )
			{
				print "not enough samplings $machine_state $#samplings\n";
				last;
			}
			
			# 50 seconds jitter
			if ( ( $lastTime - $firstTime ) > ( 240 +  50 ) )
			{
				# the window is bigger then 4 min
				print "window longer then 4 min ! - keep sampling ".($lastTime - $firstTime)." \n";
				last;	
			}
				# process Samplings
				my $max = 0;
				my $min = get_hashrate($samplings[ $#samplings - 1]);
				
				# find max
				foreach (@samplings)
				{
					my $crt_hashrate = get_hashrate($_);
					if ( $max <= $crt_hashrate )
					{
						$max = $crt_hashrate;
					}
				}
				# process only from max to the newest
				# find min in that area
				my $touch_max = 0;
				foreach (@samplings)
				{
					my $crt_hashrate = get_hashrate($_);
					if ( $touch_max == 0 )
					{
						if ( $max >= $crt_hashrate )
						{
							next;
						}
						else
						{
							$touch_max = 1;
						}
					}
					else
					{
						if ( $min >= $crt_hashrate )
						{
							$min = $crt_hashrate;
						}
					}
				}
				print "min,max $min,$max \n";
				
				my $delta_hash = $max -  $min;
				my $delta_procent = ($delta_hash * 100) / $max;
				
				if ( $delta_procent >= $win_procent )
				{
					# we should mine here
					print "A very steepe decline $delta_procent \n";
					print "Start mining \n";
					$mine_ctr = $mine_ctr_start_delay;
					$machine_state = 2;
				}
				else
				{
					#not enough decline
					print "not enough decline yet $delta_procent \n";
				}
	}
	case 2 { 
		print "Delay Mining Start $mine_ctr\n";
		if ($mine_ctr == 0 )
		{
			$mine_ctr = $mine_ctr_execution;
			$machine_state = 3;
		}
	}
	case 3 { 
		# print "Mining \n";
		
		open($file_mine_h, '>>', $file_mine) or warn "Could not open file '$file_mine' $!";
		# print "RAM $_ \n";
		print "Mining $tstmp \n";
		print $file_mine_h "$tstmp 1 \n";	
		close $file_mine_h;		
		
		if ($mine_ctr == 0 )
		{
			$mine_ctr = $mine_ctr_stop_delay;
			$machine_state = 4;
		}
	}
	case 4 { 
		print "Stopping \n";
		if ($mine_ctr == 0 )
		{
			$machine_state = 1;
		}	
	}
	else { print "State is not recognised ! \n"; } 
	}


	
	$mine_ctr--;
	sleep $sleep_interval;
}

sub net_hastrate_dificulty
{
	my $state = shift;
	my $tstmp =  timestamp();
	my $return_value;
	my @etherscan_output = `lynx -connect_timeout=15 -dump https://etherscan.io`;
	foreach (@etherscan_output)
	{
		#we are in the table
		#we can search for a correct line
		#69,513.28 GH/s  1,302.61 TH
		# print "$_";
		if ( $_ =~ m/\s*(\S*?) GH\/s\s*(\S*?) TH.*?/ )
		{		
			# print "$1 $2 \n";
			my $hashrate = $1;

			# remove comma , we need perl number 
			$hashrate =~ s/,//g;
			# print $hashrate."\n";
			my $line = $tstmp." ".$hashrate." ".$state." ";
			push @samplings, $line;
			if ( ($#samplings + 1) > $samplings_size )
			{
				shift @samplings;
			}
			last;
		}
	}
	open($file_samplings_h, '>', $file_samplings) or warn "Could not open file '$file_samplings' $!";
	foreach (@samplings)
	{
		# print "RAM $_ \n";
		print $file_samplings_h $_."\n";	
	}

	close $file_samplings_h;
}


sub timestamp {
  my $t = localtime;
  return sprintf( "%04d-%02d-%02d_%02d-%02d-%02d",
                  $t->year, $t->mon, $t->mday,
                  $t->hour, $t->min, $t->sec );
}

sub get_tstmp
{
	my $param = shift;
	if ( $param =~ /(\S*?)\s\S*?\s+\S*?\s+.*/ )
	{
		return $1;
	}
}
sub get_hashrate
{
	my $param = shift;
	if ( $param =~ /\S*?\s+(\S*?)\s+\S*?\s+.*/ )
	{
		my $hashrate = $1;
		$hashrate =~ s/,//g ;
		return $1;
	}
}
sub get_state
{
	my $param = shift;
	if ( $param =~ /\S*?\s+\S*?\s+(\S*?)\s+.*/ )
	{
		return $1;
	}
}