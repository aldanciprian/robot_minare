#!/usr/bin/perl

use LWP::Simple;                # From CPAN
use JSON qw( decode_json );     # From CPAN
use Data::Dumper;               # Perl core module
use strict;                     # Good practice
use warnings;                   # Good practice
use Time::localtime;


my $global_price = 0;
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


#nicehash
my $apiid = $ENV{'NICEHASH_APIID'};
my $apikey = $ENV{'NICEHASH_APIKEY'};
#daggerhassimoto is 20 at nicehash
my $algo=20;
my $interval=10;  #seconds
my $decline_price_int = 0; # we need 10 mins
my $decline_price_int_limit = (600 / $interval) + 1; # we need 10 mins
my $nr_bellow_limit = 3; # nr of orders bellow mine
#print Dumper decode_json( get( "https://api.nicehash.com/api" ) );


sub get_json;
sub timestamp;

my $date;

#nichash
my $decoded_json;


while (1) 
{
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
	my @active_orders;
	my $specific_order;
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
				push (@active_orders,$_);			
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
			if ( $_->{'id'} == $target_order )
			{
				my $hashref_temp = \%$_;	
				foreach ( keys%{ $hashref_temp } ){
					$specific_order->{ $_ } = $hashref_temp->{ $_ } ; 
				}
				#print "$_->{'id'}\t$_->{'price'}\t$_->{'limit_speed'}\t$_->{'workers'}\t$_->{'accepted_speed'} \n";					
			}
		}
	}
	#print "\nTIMESTAMP ".timestamp()." min price: $min_price\n";
	#$decoded_json = get_json( "https://api.nicehash.com/api?method=orders.get&my&id=$apiid&key=$apikey&key&location=0&algo=$algo" );	
	#my $date_unformated = $decoded_json->{'result'}->{'timestamp'};
	#$date= `date --date=\@$date_unformated`;
	#chomp($date);
	##print Dumper $decoded_json;
	#my $specific_order;
	#print "my orders: \n";
	#foreach (@{$decoded_json->{'result'}->{'orders'}})
	#{
		#my $hashref_temp = \%$_;	
		#print "$date:\t$_->{'id'}\t$_->{'price'}\t$_->{'limit_speed'}\t$_->{'workers'}\t$_->{'accepted_speed'} \n";
		#if ($hashref_temp->{'id'} == $target_order)
		#{
			#foreach ( keys%{ $hashref_temp } ){
				#$specific_order->{ $_ } = $hashref_temp->{ $_ } ; 
			#}
		#}
	#}
	if ( $target_order == 0 )
	{
		next;
	}
	my @bellow_orders;
	my $nr_bellow = 0;
	#print "Bellow orders that have activity: \n";
	foreach (@active_orders)
	{
		if ($_->{'workers'} > 0 )
		{
			if ($_->{'price'} <= $specific_order->{'price'})
			{
				if ($_->{'id'} != $specific_order->{'id'} )
				{
					$nr_bellow++;
					#print "$_->{'id'}\t$_->{'price'}\t$_->{'limit_speed'}\t$_->{'workers'}\t$_->{'accepted_speed'} \n";					
					push (@bellow_orders,$_);
				}
			}
		}
	}
	#print "Nr orders bellow $nr_bellow \n";

	#my %price_category_bellow;
	#my @key_list;
	
	#foreach (@bellow_orders)
	#{
		#$price_category_bellow{$_->{'price'}}++;
	#}
	#my $count = keys %price_category_bellow;

	##print "count category $count \n";
	#foreach ( sort { $a <=>$b } (keys %price_category_bellow) )
	#{
		##print "keys $_: $price_category_bellow{$_} "; 
		#push (@key_list,$_);
	#}
	##print "\n";
	my $target_price = 0;
	#$target_price = detect_target_category(\%price_category_bellow,\@key_list,0,0);
	$target_price = $min_price + 0.0001;
	if ( $global_price > $target_price )
	{
		if ( ($global_price - $target_price ) > 0.0005 )
		{
			print timestamp()." DOWN  ".($global_price - $target_price)." $global_price $target_price $min_price\n";
		}
		else
		{
			print timestamp()." Could go DOWN ".($global_price - $target_price)." $global_price $target_price $min_price\n";

		}
	}
	else
	{
		if ($global_price < $target_price )
		{
		print timestamp()." UP  ".($global_price - $target_price)." $global_price $target_price $min_price\n";
		}
		else
		{
		print timestamp()." CONST  ".($global_price - $target_price)." $global_price $target_price $min_price\n";
		}
	}
		$global_price = $target_price;
	#if ( $count < 3 )
	#{
		#my $sum_orders_bellow = 0;
		#$sum_orders_bellow = $price_category_bellow{}
	#}
	#if ( $key_list[0] )
	if ( $min_price <= 0.0760 )
	{
		if ( $nr_bellow > $nr_bellow_limit )
		{
			#print "to decrease \n";
#			if ($specific_order->{'limit_speed'} < $sum_limit_speed_bellow )
#			{
				#decrese speed
				if ( $decline_price_int == 0 )
				{
#					$decoded_json=get_json("https://api.nicehash.com/api?method=orders.set.price.decrease&id=$apiid&key=$apikey&location=0&algo=$algo&order=$specific_order->{'id'}");
					#print Dumper $decoded_json;
#					if ( exists $decoded_json->{'result'}->{'success'} )
					{
						#print "decrease success \n";
						$decline_price_int = $decline_price_int_limit;
					}
				#else
					#{
						#print  "decrease error \n";
					#}
				}
#			}
		}
		else
		{
			#increase speed
			#print "to increase \n";
			my $increase_price = $specific_order->{'price'} +  0.0001;
			print "increase price with $increase_price \n";
			#$decoded_json=get_json("https://api.nicehash.com/api?method=orders.set.price&id=$apiid&key=$apikey&location=0&algo=$algo&order=$specific_order->{'id'}&price=$increase_price");
			#print Dumper $decoded_json;		
		}
	}
	
	
	#
	if ($decline_price_int > 0 )
	{
		$decline_price_int--;
	}
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

sub detect_target_category {
	my $price_cat_hash_ref = shift;
	my %price_cat_hash = %$price_cat_hash_ref;

	my $temp_key_list_ref = shift;
	my @temp_key_list = @$temp_key_list_ref;

	my $temp_level = shift;
	my $temp_sum_orders = shift;
	#foreach (sort {$a <=> $b } (keys %price_cat_hash))
	#{
		##print "ry: $_ $price_cat_hash{$_} \n";
	#}

	$temp_sum_orders = $temp_sum_orders +  $price_cat_hash{$temp_key_list[$temp_level]};
	if ( $temp_sum_orders > 3 )
	{
		#done
		print "reached level $temp_level  price $temp_key_list[$temp_level] nr order $temp_sum_orders \n";
		return $temp_key_list[$temp_level];
	}
	else
	{
		$temp_level = $temp_level + 1 ;
		detect_target_category($price_cat_hash_ref,$temp_key_list_ref,$temp_level,$temp_sum_orders);
	}
	#foreach (keys %price_cat_hash)
	#{
		#print "detect_target_category: $_ $price_cat_hash{$_} \n";
	#}

	#foreach (@temp_key_list)
	#{
		#print "detect_target_category: $_ \n";
	#}

}
