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
sub get_specific_order_hash;

#nanopool
my $eth_add = $ENV{'ETH_ADD'};

#nicehash
my $apiid = $ENV{'NICEHASH_APIID'};
my $apikey = $ENV{'NICEHASH_APIKEY'};
my $algo = 20;


my $current_eth_balance = 0;
my $previous_eth_balance = 0;
my $delta_eth = 0;
my $round_delta_eth = 0;
my $previous_delta_eth = 0;
my $global_delta_eth = 0;
my $current_btc_balance = 0;
my $previous_btc_balance = 0;
my $delta_btc = 0;
my $round_delta_btc = 0;
my $previous_delta_btc = 0;
my $global_delta_btc = 0;


my $interval = 30;

my $decoded_json;
my $specific_order;
my $target_order;
if (defined $ARGV[0])
{
	$target_order = $ARGV[0];
}
else
{
	$target_order = 0;
}

my $filename = 'balance_log.txt';
open(my $fh, '>>', $filename) or die "Could not open file '$filename' $!";


while (1)
{

	$decoded_json = get_json_curl("https://api.nanopool.org/v1/eth/balance/$eth_add");
	 # print Dumper $decoded_json;
	$current_eth_balance = $decoded_json->{'data'};

	$specific_order	= get_specific_order_hash();
	if (defined $specific_order->{'id'} )	
	{
		#we found the target order 
		# print Dumper $specific_order;
		# print "\n";
		#print " yes target order \n";
	}
	else
	{
		#we didn't found the target order
		#print " no target order \n";
		sleep 10;
		next;		
	}	

	$current_btc_balance = $specific_order->{'btc_paid'};

	
	if ( $previous_eth_balance != $current_eth_balance )
	{
		$delta_eth = ($current_eth_balance - $previous_eth_balance);
		if ( $previous_delta_eth != $delta_eth )
		{
			$round_delta_eth = $delta_eth - $previous_delta_eth;
			$previous_delta_eth = $delta_eth;
		}
		$previous_eth_balance = $current_eth_balance;
		# print "$delta_eth ETH \n";
	}

	if ( $previous_btc_balance != $current_btc_balance )
	{
		$delta_btc = ($current_btc_balance - $previous_btc_balance);
		
		if ( $previous_delta_btc != $delta_btc )
		{
			$round_delta_btc = $delta_btc - $previous_delta_btc;
			$previous_delta_btc = $delta_btc;
		}

		
		$previous_btc_balance = $current_btc_balance;
		# print "$delta_btc BTC\n";
	}	

	my $multiplication = $current_btc_balance * 10;
	$global_delta_eth = $current_eth_balance - $multiplication ;
	my $division =  ($current_eth_balance / 10 );
	$global_delta_btc = ($current_btc_balance - $division);
	# print "multi $multiplication divi $division \n";
	print timestamp().": ".sprintf("%0.15f",$current_eth_balance)." ; ".sprintf("%0.15f",$delta_eth)." ; ".sprintf("%0.15f",$round_delta_eth)." ; [".sprintf("%0.15f",$global_delta_eth)."]E->";
	print " ".sprintf("%0.15f",$current_btc_balance)." ; ".sprintf("%0.15f",$delta_btc)." ; ".sprintf("%0.15f",$round_delta_btc)." ; [".sprintf("%0.15f",$global_delta_btc)." ]B\n";
	

	print $fh timestamp().": ".sprintf("%0.15f",$current_eth_balance)." ; ".sprintf("%0.15f",$delta_eth)." ; ".sprintf("%0.15f",$round_delta_eth)." ; [".sprintf("%0.15f",$global_delta_eth)."] ETH -> " ;
	print $fh " ".sprintf("%0.15f",$current_btc_balance)." ; ".sprintf("%0.15f",$delta_btc)." ; ".sprintf("%0.15f",$round_delta_btc)." ; [".sprintf("%0.15f",$global_delta_btc)." ] BTC \n";
	
	
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


sub get_specific_order_hash
{
	$decoded_json = get_json( "https://api.nicehash.com/api?method=orders.get&my&id=$apiid&key=$apikey&key&location=0&algo=$algo" );	
	my $date_unformated = $decoded_json->{'result'}->{'timestamp'};
	my $date= `date --date=\@$date_unformated`;
	chomp($date);
	##print Dumper $decoded_json;
	# print "my orders: \n";
	foreach (@{$decoded_json->{'result'}->{'orders'}})
	{
		my $hashref_temp = \%$_;	
		# print "$date:\t$_->{'id'}\t$_->{'price'}\t$_->{'limit_speed'}\t$_->{'workers'}\t$_->{'accepted_speed'} \n";
		# print $fh "$date:\t$_->{'id'}\t$_->{'price'}\t$_->{'limit_speed'}\t$_->{'workers'}\t$_->{'accepted_speed'} \n";		
		if ($hashref_temp->{'id'} == $target_order)
		{
			foreach ( keys%{ $hashref_temp } ){
				$specific_order->{ $_ } = $hashref_temp->{ $_ } ; 
			}
		}
	}
	return \%$specific_order;
}