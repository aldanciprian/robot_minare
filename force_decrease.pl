#!/usr/bin/perl 

use LWP::Simple;                # From CPAN
use JSON qw( decode_json );     # From CPAN
use Data::Dumper;               # Perl core module
use strict;                     # Good practice
use warnings;                   # Good practice
use Time::localtime;
use Time::Piece;


my $target_order;
if (defined $ARGV[0])
{
	$target_order = $ARGV[0];
}
else
{
	$target_order = 0;
	print "No target order ! \n";
	exit 0;
}



#nanopool
my $eth_add = $ENV{'ETH_ADD'};


my $order_id=$ARGV[1];
my $date;
my $decoded_json;
#nicehash
my $apiid = $ENV{'NICEHASH_APIID'};
my $apikey = $ENV{'NICEHASH_APIKEY'};
#daggerhassimoto is 20 at nicehash
my $algo=20;
my $interval=1;  #seconds
my $decline_price_int = 0; # we need 10 mins
my $decline_price_int_limit = (600 / $interval) + 1; # we need 10 mins
my $nr_bellow_limit = 3; # nr of orders bellow mine
my $target_price = 0; #current target price

#print Dumper decode_json( get( "https://api.nicehash.com/api" ) );


sub get_json;
sub timestamp;



while (1) 
{
	print "============================= FOLLOW NANOPOOL ".timestamp()."  $$ ======================\n";
	$decoded_json=get_json("https://api.nicehash.com/api?method=orders.set.price.decrease&id=$apiid&key=$apikey&location=0&algo=$algo&order=$target_order");
	print Dumper $decoded_json;
	sleep  $interval;
}


#gets url returns result object in json decoded  
sub get_json
{
	my $json;
	my $decode_json;
	my $url = shift;
	# 'get' is exported by LWP::Simple; install LWP from CPAN unless you have it.
	# You need it or something similar (HTTP::Tiny, maybe?) to get web pages.
	$json = get( $url );
	#print "curl --silent $url \n" ;
	#$json = `curl --silent $url`;
	warn "Could not get $url  !" unless defined $json;


	# Decode the entire JSON
	$decode_json = decode_json( $json );
	return $decode_json

#	print Dumper $decoded_json;	
}

sub timestamp {
  my $t = localtime;
  return sprintf( "%04d-%02d-%02d_%02d-%02d-%02d",
                  $t->year + 1900, $t->mon + 1, $t->mday,
                  $t->hour, $t->min, $t->sec );
}
