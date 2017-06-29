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

my $decoded_json;
#print get( "https://api.nicehash.com/api" );
#print `curl  "https://api.nicehash.com/api" `;

#print Dumper decode_json( get( "https://api.nicehash.com/api" ) );
#
#
#print Dumper get_json("https://api.nanopool.org/v1/eth/accountexist/$eth_add") ;
#print Dumper decode_json(`curl --silent https://api.nanopool.org/v1/eth/accountexist/$eth_add `);
#print Dumper get_json("https://api.nanopool.org/v1/eth/pool/hashrate");
#print Dumper get_json("https://api.nanopool.org/v1/eth/block_stats/10/10");
	## 3220461
#$decoded_json = get_json("https://api.nanopool.org/v1/eth/network/lastblocknumber");
#my $delta = $decoded_json->{'data'} - 3220461 - 40  ;
##$decoded_json = get_json("https://api.nanopool.org/v1/eth/block_stats/0/11");
##print Dumper $decoded_json;
##foreach (@{$decoded_json->{'data'}})
##{
	##my $realdate = `date --date=\@$_->{'date'}`;
	##print " $realdate ";
##}

##$decoded_json = get_json("https://api.nanopool.org/v1/eth/blocks/3898257/1");
#$decoded_json = get_json("https://api.nanopool.org/v1/eth/blocks/$delta/41");
##print Dumper $decoded_json;
#foreach (@{$decoded_json->{'data'}})
#{
	#my $realdate = `date --date=\@$_->{'date'}`;
	#print "$_->{'number'} $realdate ";
#}

#$decoded_json = get_json("https://api.nanopool.org/v1/eth/balance_hashrate/$eth_add");
#print Dumper $decoded_json;
#print "balance $decoded_json->{'data'}->{'balance'} status $decoded_json->{'data'}->{'status'} \n" ;

$decoded_json = get_json("https://api.nanopool.org/v1/eth/user/$eth_add");
print Dumper $decoded_json;
#gets url returns result object in json decoded  
sub get_json
{
	my $json;
	my $decoded_json;
	my $url = shift;
	# 'get' is exported by LWP::Simple; install LWP from CPAN unless you have it.
	# You need it or something similar (HTTP::Tiny, maybe?) to get web pages.
	#$json = get( $url );
	print "curl --silent $url\n";
	$json = `curl  --silent $url `;
	warn "Could not get $url  !" unless defined $json;
	#print $json;


	# Decode the entire JSON
	print "$json\n";
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
