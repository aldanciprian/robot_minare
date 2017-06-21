#!/usr/bin/perl 

use LWP::Simple;                # From CPAN
use JSON qw( decode_json );     # From CPAN
use Data::Dumper;               # Perl core module
use strict;                     # Good practice
use warnings;                   # Good practice
use Time::localtime;


my $target_order;
if (defined $ARGV[0])
{
	$target_order = $ARGV[0];
}
else
{
	$target_order = 0;
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
my $interval=10;  #seconds
my $decline_price_int = 0; # we need 10 mins
my $decline_price_int_limit = (600 / $interval) + 1; # we need 10 mins
my $nr_bellow_limit = 3; # nr of orders bellow mine
my $target_price = 0; #current target price

#print Dumper decode_json( get( "https://api.nicehash.com/api" ) );


sub get_json;
sub timestamp;
sub keep_price_to_min;



while (1) 
{
	print "============================= FOLLOW NANOPOOL ".timestamp()."  $$ ======================\n";
	keep_price_to_min();
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
sub keep_price_to_min {
	$decoded_json = get_json( "https://api.nicehash.com/api?method=orders.get&location=0&algo=$algo" );
	#print Dumper $decoded_json;
	#print ref($decoded_json->{'result'}->{'orders'});
	my $min_price = 1000000;
	my $min_fixed_price = 1000000; 
	my @active_orders;
	my $specific_order;
	foreach (@{$decoded_json->{'result'}->{'orders'}})
	{

		if ( $_->{'alive'} == 1 )
		{	
			if ( $_->{'type'} == 1 )
			{
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
				push (@active_orders,$_);			
				#if ( $_->{'accepted_speed'} > 0 )
				if ( $_->{'workers'} > 0 )
				{
					if ( $min_price > $_->{'price'} )
					{
						$min_price = $_->{'price'};
					}
				}
			}
			if ( $_->{'id'} == $target_order )
			{
				my $hashref_temp = \%$_;	
				foreach ( keys%{ $hashref_temp } ){
					$specific_order->{ $_ } = $hashref_temp->{ $_ } ; 
				}
				print "$_->{'id'}\t$_->{'price'}\t$_->{'limit_speed'}\t$_->{'workers'}\t$_->{'accepted_speed'} \n";					
			}
		}
	}
	print "\nTIMESTAMP ".timestamp()." min price: $min_price\n";
	$decoded_json = get_json( "https://api.nicehash.com/api?method=orders.get&my&id=$apiid&key=$apikey&key&location=0&algo=$algo" );	
	my $date_unformated = $decoded_json->{'result'}->{'timestamp'};
	$date= `date --date=\@$date_unformated`;
	chomp($date);
	##print Dumper $decoded_json;
	print "my orders: \n";
	foreach (@{$decoded_json->{'result'}->{'orders'}})
	{
		my $hashref_temp = \%$_;	
		print "$date:\t$_->{'id'}\t$_->{'price'}\t$_->{'limit_speed'}\t$_->{'workers'}\t$_->{'accepted_speed'} \n";
		if ($hashref_temp->{'id'} == $target_order)
		{
			foreach ( keys%{ $hashref_temp } ){
				$specific_order->{ $_ } = $hashref_temp->{ $_ } ; 
			}
		}
	}
	if ( $target_order == 0 )
	{
		next;
	}
	# don't go higher then 0.700
	if ( $min_price <= 0.0700 )
	{
		$target_price = $min_price + 0.0002;
		if ( $specific_order->{'price'} > $target_price )
		{
			#decrease
			if ( ($specific_order->{'price'} - $target_price ) > 0.0002 )
			{
				print timestamp()." DOWN  ".($specific_order->{'price'} - $target_price)." $specific_order->{'price'} $target_price $min_price\n";
				#decrese speed
				if ( $decline_price_int == 0 )
				{
					$decoded_json=get_json("https://api.nicehash.com/api?method=orders.set.price.decrease&id=$apiid&key=$apikey&location=0&algo=$algo&order=$specific_order->{'id'}");
					print Dumper $decoded_json;
					if ( exists $decoded_json->{'result'}->{'success'} )
					{
						print "decrease success \n";
						$decline_price_int = $decline_price_int_limit;
					}
					else
					{
						print  "decrease error \n";
					}
				}
			}
			else
			{
				print timestamp()." Could go DOWN ".($specific_order->{'price'} - $target_price)." $specific_order->{'price'} $target_price $min_price\n";

			}
		}
		else
		{
			#increase
			if ($specific_order->{'price'} < $target_price )
			{
				print timestamp()." UP  ".($specific_order->{'price'} - $target_price)." $specific_order->{'price'} $target_price $min_price\n";
				#print "to increase \n";
				my $increase_price = $specific_order->{'price'} +  0.0001;
				print "increase price with $increase_price \n";
				$decoded_json=get_json("https://api.nicehash.com/api?method=orders.set.price&id=$apiid&key=$apikey&location=0&algo=$algo&order=$specific_order->{'id'}&price=$increase_price");
				#print Dumper $decoded_json;		
				
			}
			else
			{
				#constant
				print timestamp()." CONST  ".($specific_order->{'price'} - $target_price)." $specific_order->{'price'} $target_price $min_price\n";
				if ($specific_order->{'workers'} == 0 )
				{
					my $increase_price = $specific_order->{'price'} +  0.0001;
					print "special condition increase price with $increase_price \n";
					$decoded_json=get_json("https://api.nicehash.com/api?method=orders.set.price&id=$apiid&key=$apikey&location=0&algo=$algo&order=$specific_order->{'id'}&price=$increase_price");
					#print Dumper $decoded_json;		
					
				}
			}
		}
	}
	
	if ($decline_price_int > 0 )
	{
		$decline_price_int--;
	}
}
