#!/usr/bin/perl

use LWP::Simple;                # From CPAN
use JSON qw( decode_json );     # From CPAN
use Data::Dumper;               # Perl core module
use strict;                     # Good practice
use warnings;                   # Good practice
use Time::localtime;

#nanopool
my $eth_add = $ENV{'ETH_ADD'};


#nicehash
my $apiid = $ENV{'NICEHASH_APIID'};
my $apikey = $ENV{'NICEHASH_APIKEY'};
#daggerhassimoto is 20 at nicehash
my $algo=20;
my $interval=10;  #seconds
my $decline_price_int = 0; # 10 mins

#print Dumper decode_json( get( "https://api.nicehash.com/api" ) );


sub get_json;

sub timestamp;



while (1) 
{
	#nichash
	my $decoded_json;
	$decoded_json = get_json( "https://api.nicehash.com/api?method=stats.global.current" );	
#	print "Current profitability \n";
#	print Dumper $decoded_json->{'result'}->{'stats'}[$algo];
	print "GC $decoded_json->{'result'}->{'stats'}[$algo]->{'profitability_eth'} $decoded_json->{'result'}->{'stats'}[$algo]->{'price'} $decoded_json->{'result'}->{'stats'}[$algo]->{'speed'} \n";

	# stats.global.24h
	$decoded_json = get_json( "https://api.nicehash.com/api?method=stats.global.24h" );	
#	print "Last 24h profitability \n";
#	print Dumper $decoded_json->{'result'}->{'stats'}[20];	
	print "G24H $decoded_json->{'result'}->{'stats'}[$algo]->{'price'} $decoded_json->{'result'}->{'stats'}[$algo]->{'speed'} \n";

	
	
	$decoded_json = get_json( "https://api.nicehash.com/api?method=orders.get&location=0&algo=$algo" );
	#print Dumper $decoded_json;
	#print ref($decoded_json->{'result'}->{'orders'});
	my $min_price = 1000000;
	my $min_fixed_price = 1000000; 
	my $sum_limit_speed = 0;
	my $sum_accepted_speed = 0;
	my $sum_fixed_accepted_speed = 0;
	my $sum_standard_accepted_speed = 0;
	my $sum_fixed_limit_speed = 0;
	my $sum_standard_limit_speed = 0;
	foreach (@{$decoded_json->{'result'}->{'orders'}})
	{
		if ( $_->{'alive'} == 1 )
		{	
		$sum_accepted_speed = $sum_accepted_speed + $_->{'accepted_speed'};
		$sum_limit_speed = $sum_limit_speed + $_->{'limit_speed'};
			if ( $_->{'type'} == 1 )
			{
				$sum_fixed_accepted_speed += $_->{'accepted_speed'};		
				$sum_fixed_limit_speed += $_->{'limit_speed'};	
				if ( $min_fixed_price > $_->{'price'} )
				{
					$min_fixed_price = $_->{'price'};
				}
			}

			# print $_->{'id'}."\t";
			# print $_->{'type'}."\t";
			# print $_->{'workers'}."\t";
			# print $_->{'price'}."\t";	
			# print $_->{'limit_speed'}."\t";			
			# print $_->{'accepted_speed'}."\n";	
			# get the minimum price where is mining for standard;
			if ( $_->{'type'} == 0 )
			{
				$sum_standard_accepted_speed += $_->{'accepted_speed'};
				$sum_standard_limit_speed += $_->{'limit_speed'};				
				#if ( $_->{'accepted_speed'} > 0 )
				if ( $_->{'workers'} > 0 )
				{
					if ( $min_price > $_->{'price'} )
					{
						$min_price = $_->{'price'};
					}
				}
			}
		}
	}
	
	$decoded_json = get_json( "https://api.nicehash.com/api?method=orders.get&my&id=$apiid&key=$apikey&key&location=0&algo=$algo" );	
	
	#print Dumper $decoded_json;
	my $tstmp = timestamp();
	
	my $csv = 'orders.csv';
	open(my $fh, '>>', $csv) or die "Could not open file '$csv' $!";
	print "$tstmp; mp - $min_price ; us - $sum_accepted_speed ; ufs - $sum_fixed_accepted_speed ; usts - $sum_standard_accepted_speed ; ls  - $sum_limit_speed ;  lfs - $sum_fixed_limit_speed ;  lsts - $sum_standard_limit_speed ; \n";	
	foreach (@{$decoded_json->{'result'}->{'orders'}})
	{
		print "$tstmp, $_->{'id'}, $_->{'price'}, $_->{'workers'}, $_->{'limit_speed'}, $_->{'accepted_speed'}, $_->{'btc_paid'}, $_->{'btc_avail'} \n";	
		print $fh "$tstmp, $_->{'id'}, $_->{'price'}, $_->{'workers'}, $_->{'limit_speed'}, $_->{'accepted_speed'}, $_->{'btc_paid'}, $_->{'btc_avail'} \n";			
	}
	close $fh;	

	$csv = 'report.csv';
	open($fh, '>>', $csv) or die "Could not open file '$csv' $!";
	print $fh "$tstmp,$min_price,$sum_accepted_speed,$sum_fixed_accepted_speed,$sum_standard_accepted_speed,$sum_limit_speed,$sum_fixed_limit_speed,$sum_standard_limit_speed \n";
	sleep 1;
	close $fh;

	
	#nanopool
	my $curl_results = `curl https://api.nanopool.org/v1/eth/accountexist/$eth_add `; 
	#$decoded_json = get_json("https://api.nanopool.org/v1/eth/accountexist/$eth_add");
	#$decoded_json = $curl_results;
	#print Dumper $decoded_json;	
	#$decoded_json = get_json("https://api.nanopool.org/v1/eth/user/$eth_add");
	#$decoded_json = get_json("https://api.nanopool.org/v2/eth/network/avgblocktime");
	#print Dumper $decoded_json;		

	# if ( $decline_price_int == 0 )
	# {
		# $decoded_json = get_json("https://api.nicehash.com/api?method=orders.set.price.decrease&id=$apiid&key=$apikey&key&location=0&algo=$algo&order=3004522");
		# $decline_price_int = 60;
	# }
	# else
	# {
		# $decline_price_int -= 1;	
	# }	

	

	sleep $interval;
}



#gets url returns result object in json decoded  
sub get_json
{
	my $json;
	my $decoded_json;
	my $url = shift;
	# 'get' is exported by LWP::Simple; install LWP from CPAN unless you have it.
	# You need it or something similar (HTTP::Tiny, maybe?) to get web pages.
	$json = get( $url );
	warn "Could not get $url  !" unless defined $json;


	# Decode the entire JSON
	$decoded_json = decode_json( $json );
	return $decoded_json

#	print Dumper $decoded_json;	
}

sub timestamp {
  my $t = localtime;
  return sprintf( "%04d-%02d-%02d_%02d-%02d-%02d",
                  $t->year + 1900, $t->mon + 1, $t->mday,
                  $t->hour, $t->min, $t->sec );
}
