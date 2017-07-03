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


#$VAR1 = {
          #'data' => {
                      #'balance' => '0.00012814',
                      #'unconfirmed_balance' => '0.00000000',
                      #'workers' => [
                                     #{
                                       #'hashrate' => '76.5',
                                       #'lastShare' => 1498724384,
                                       #'avg_h1' => '35.4',
                                       #'id' => 'aldanciprian',
                                       #'avg_h24' => '1.5',
                                       #'avg_h3' => '11.8',
                                       #'avg_h6' => '5.9',
                                       #'avg_h12' => '3.0',
                                       #'rating' => 0
                                     #}
                                   #],
                      #'hashrate' => '76.5',
                      #'avgHashrate' => {
                                         #'h1' => '35.4',
                                         #'h6' => '5.9',
                                         #'h3' => '11.8',
                                         #'h12' => '3.0',
                                         #'h24' => '1.5'
                                       #},
                      #'account' => '0x01e4817973708a034014a5ffac6514862bc1ff5b'
                    #},
          #'status' => bless( do{\(my $o = 1)}, 'JSON::PP::Boolean' )
        #};

$decoded_json = get_json("https://api.nanopool.org/v1/eth/user/$eth_add");
# print Dumper $decoded_json;
print timestamp()." ";
print "$decoded_json->{'data'}->{'balance'} ";
print "$decoded_json->{'data'}->{'hashrate'} - ";
if ( defined $decoded_json->{'data'}->{'workers'}[0] )
{
	print "$decoded_json->{'data'}->{'workers'}[0]->{'hashrate'} ";
	print "$decoded_json->{'data'}->{'workers'}[0]->{'lastShare'} ";
}
print " \n";
# $decoded_json = get_json("https://api.nanopool.org/v1/eth/network/lastblocknumber");
# $decoded_json = get_json("https://api.nanopool.org/v1/eth/shareratehistory/$eth_add");
# print Dumper $decoded_json;
# print "last block number $decoded_json->{'data'} \n";
#gets url returns result object in json decoded  
sub get_json
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
                  $t->year + 1900, $t->mon + 1, $t->mday,
                  $t->hour, $t->min, $t->sec );
}
