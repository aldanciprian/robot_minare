#!/usr/bin/perl 

use LWP::Simple;                # From CPAN
use JSON qw( decode_json );     # From CPAN
use Data::Dumper;               # Perl core module
use strict;                     # Good practice
use warnings;                   # Good practice
use Time::localtime;
use Time::Piece;


sub get_json;
sub get_json_curl;
sub timestamp;
sub trim;

#nanopool
my $eth_add = $ENV{'ETH_ADD'};

#nicehash
my $apiid = $ENV{'NICEHASH_APIID'};
my $apikey = $ENV{'NICEHASH_APIKEY'};
my $algo = 20;


my $miners = 0;
my $workers = 0;
my $hashrate = 0;
my $last_block_number = 0;
my $next_epoch = 0;


my $interval = 30;

my $decoded_json;

my $tstmp;
my $filename = "$0_log.txt";
open(my $fh, '>>', $filename) or die "Could not open file '$filename' $!";


while (1)
{
	$tstmp = timestamp();
	print "$tstmp: ";
	print $fh "$tstmp: ";
	
	$decoded_json = get_json_curl("https://api.nanopool.org/v1/eth/pool/activeminers");
	# print Dumper $decoded_json;
	$miners = $decoded_json->{'data'};

	$decoded_json = get_json_curl("https://api.nanopool.org/v1/eth/pool/activeworkers");
	$workers = $decoded_json->{'data'};
	
	$decoded_json = get_json_curl("https://api.nanopool.org/v1/eth/pool/hashrate");
	$hashrate = $decoded_json->{'data'};	
	
	print "Miners $miners Workers $workers Hashrate $hashrate ";
	print $fh "Miners $miners Workers $workers Hashrate $hashrate ";
	
	$decoded_json = get_json_curl("https://api.nanopool.org/v1/eth/network/lastblocknumber");
	$last_block_number = $decoded_json->{'data'};		
	
	$decoded_json = get_json_curl("https://api.nanopool.org/v1/eth/network/timetonextepoch");
	$next_epoch = $decoded_json->{'data'};			
	
	print "LastBlock $last_block_number NextEpoch $next_epoch s \n";
	print $fh "LastBlock $last_block_number NextEpoch $next_epoch s \n";
	
	# print $fh timestamp().": ".sprintf("%0.15f",$current_eth_balance)." ; ".sprintf("%0.15f",$delta_eth)." ; ".sprintf("%0.15f",$round_delta_eth)." ; [".sprintf("%0.15f",$global_delta_eth)."] ETH -> " ;
	# print $fh " ".sprintf("%0.15f",$current_btc_balance)." ; ".sprintf("%0.15f",$delta_btc)." ; ".sprintf("%0.15f",$round_delta_btc)." ; [".sprintf("%0.15f",$global_delta_btc)." ] BTC \n";
	
	
	sleep $interval;
}

close $fh;	
	


#gets url returns result object in json decoded  
sub get_json
{
	my $json;
	my $decode_json;
	my $url = shift;
	# 'get' is exported by LWP::Simple; install LWP from CPAN unless you have it.
	# You need it or something similar (HTTP::Tiny, maybe?) to get web pages.
	$json = get( $url );
	#sleep 250ms
	select(undef, undef, undef, 0.25);
	#print "curl --silent $url \n" ;
	#$json = `curl --silent $url`;
	warn "Could not get $url  !" unless defined $json;
	# print $json;

	# Decode the entire JSON
	$decode_json = decode_json( $json );
	return $decode_json

#	print Dumper $decoded_json;	
}


#gets url returns result object in json decoded  
sub get_json_curl
{
	my $json;
	my $decoded_json;
	my $url = shift;
	# 'get' is exported by LWP::Simple; install LWP from CPAN unless you have it.
	# You need it or something similar (HTTP::Tiny, maybe?) to get web pages.
	#$json = get( $url );
	# print "curl --silent $url\n";
	$json = `curl  --silent $url `;
	warn "Could not get $url  !" unless defined $json;
	#print $json;


	# Decode the entire JSON
	#print "$json\n";
	$decoded_json = decode_json( $json );
	return $decoded_json

#	print Dumper $decoded_json;	
}

sub timestamp {
  my $t = localtime;
  return sprintf( "%04d-%02d-%02d_%02d-%02d-%02d",
                  $t->year, $t->mon, $t->mday,
                  $t->hour, $t->min, $t->sec );
}

sub trim {
	my $input = shift;
	$input =~ s/^\s+|\s+$//g;
	return $input;
}


