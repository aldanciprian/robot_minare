#!/usr/bin/perl 

use LWP::Simple;                # From CPAN
use JSON qw( decode_json );     # From CPAN
use Data::Dumper;               # Perl core module
use strict;                     # Good practice
use warnings;                   # Good practice
use Time::localtime;
use Time::Piece;


#alina GLOBALE#
my @_24HrsBlocks = ();
my %crtBlocks =();
my @lastXBlocks =();


my $target_order;
if (defined $ARGV[0])
{
	$target_order = $ARGV[0];
}
else
{
	$target_order = 0;
}

#hash with block timestamp as key
my %total_blocks;


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
my $blocks_threshold = 2; #threshold for number of blocks from start of timeframe
my $currentHighSpeed = 0; # on off for current mining highSpeed
my $specific_order; # the hash of the target order	
my $startDiffInt = 150; # 150 seconds from the start of the timeframe
my $endDiffInt = 300; # 300 seconds until the end of the timeframe
my $resetDiffInt = 130; # 130 seconds until the end of the timeframe to reset the speed

my $old_startCrtTF = 0; # the old crt TF 



my $max_speed = 2.5;
my $min_speed = 0.1;

#print Dumper decode_json( get( "https://api.nicehash.com/api" ) );


my $filename = 'control_order_log.txt';
open(my $fh, '>>', $filename) or die "Could not open file '$filename' $!";




sub get_json;
sub read_monitor_ether_log;
sub timestamp;
sub keep_price_to_min;
sub decrease_price;
sub decrease_speed;
sub increase_speed;
sub count_blocks_tick;
sub getTimeIndexes;
sub getPreviousIndex;
sub processLogEntry;
sub getPrevious;
sub getCrt;


#init
#init 24HRS array
for my $j (0..23)
{
for my $k (0..5)
{
  $_24HrsBlocks[$j]{$k}= {};
}
}

#read the last 40 blocks from log
read_monitor_ether_log();




while (1) 
{
	my $while_tstmp = timestamp();
	print "============================= FOLLOW NANOPOOL $while_tstmp  $$ ======================\n";
	print "Start ".timestamp()."\n";
	count_blocks_tick();
	getCrt();
	print "timeframe crt: $crtBlocks{'timeFrame'} blocks:  $crtBlocks{'noOfBlocks'} uncles: $crtBlocks{'uncles'} - ";
	print $fh "TimeStamp crt : $while_tstmp timeframe: $crtBlocks{'timeFrame'} blocks:  $crtBlocks{'noOfBlocks'} uncles: $crtBlocks{'uncles'}  - ";
	foreach (keys (%{$crtBlocks{'blocks'}}))
	{
		print "$_ ";
		print $fh "$_ ";
	}
	print "\n";
	print $fh "\n";

	#alina new
	my $noOfPrevTimeFrames = 5;
	getPrevious($noOfPrevTimeFrames);
	for my $i (0..($noOfPrevTimeFrames-1))
	{
		print "timeframe: $lastXBlocks[$i]{'timeFrame'} blocks:  $lastXBlocks[$i]{'noOfBlocks'} uncles: $lastXBlocks[$i]{'uncles'} - ";
		print $fh "TimeStamp: $while_tstmp timeframe: $lastXBlocks[$i]{'timeFrame'} blocks:  $lastXBlocks[$i]{'noOfBlocks'} uncles: $lastXBlocks[$i]{'uncles'} - ";
		foreach (keys (%{$lastXBlocks[$i]{'blocks'}}))
		{
		  print "$_ ";
		  print $fh "$_ ";	
		}
		print "\n";
		print $fh "\n";
	}
	#alina end new

	
	
	##alina timeDiff
	my $crtTime =   Time::Piece->strptime($while_tstmp,'%Y-%m-%d_%H-%M-%S');
	my $minute = 0;
	{
	  use integer;
	  $minute = $crtTime->strftime("%M");
	  #print "zeci de minute ".((($minute+0)/10)*10)."\n";
	  $minute = (($minute+0)/10)*10;
	}
	my $startMinute = sprintf("%02s",$minute);
	my $startTime = $crtTime->strftime("%Y-%m-%d_%H-$startMinute-00");
	$startTime = Time::Piece->strptime($startTime,'%Y-%m-%d_%H-%M-%S');
	
	if ($old_startCrtTF != $startTime )
	{
		# a new TF begin
		#force low speed and price decrease
		$old_startCrtTF = $startTime;		
		$currentHighSpeed = 0;
		decrease_speed();
	}

	# print "crt time $crtTime $minute $startMinute \n";
	# print "start time $startTime \n";
	
	my $endMinute = sprintf("%02s",($minute+9));
	my $endTime = $crtTime->strftime("%Y-%m-%d_%H-$endMinute-59");
	$endTime = Time::Piece->strptime($endTime,'%Y-%m-%d_%H-%M-%S');
	# print "end time $endTime \n";				
	my $startDiff = $crtTime - $startTime;
	my $endDiff = $endTime - $crtTime;
	print "start end diff $startDiff  $endDiff [ > $startDiffInt -  > $endDiffInt ] \n ";
	if (($startDiff > $startDiffInt ) && ( $endDiff > $endDiffInt))
	{
	  #do something
	  print "in interval \n";
	  if ( $crtBlocks{'noOfBlocks'} >= $blocks_threshold )
	  {
		if ( $currentHighSpeed == 0 )
		{
			print "Increasing speed ,starting  $crtBlocks{'noOfBlocks'} blocks at time $while_tstmp \n";
			print $fh "Increase speed ,starting  $crtBlocks{'noOfBlocks'} blocks at time $while_tstmp \n";
			$currentHighSpeed = 1;
			#increase speed
			increase_speed();
		}
	  }
	}
	else
	{
		print "in afara intervalului \n";
		
		if ( $endDiff < $resetDiffInt )
		{
			#the last 40 sec of the interval reset to 0.1
			if ( $currentHighSpeed == 1 )
			{
				#decrease speed	  
				print "set speed to min 0.1 at $crtBlocks{'noOfBlocks'} blocks at time $while_tstmp \n";
				print $fh "set speed to min 0.1 at $crtBlocks{'noOfBlocks'} blocks at time $while_tstmp \n";				
				$currentHighSpeed = 0 ;						
				decrease_speed();
			}
		}
	}
	#end alina necompilat
	
	
	#print "$crtBlocks{'timeFrame'}";

	# print Dumper %crtBlocks;	
	#alina new
	# my $noOfPrevTimeFrames = 5;
	# getPrevious($noOfPrevTimeFrames);
	# for my $i (0..($noOfPrevTimeFrames-1))
	# {
  	  # print "timeframe: $lastXBlocks[$i]{'timeFrame'} blocks:  $lastXBlocks[$i]{'noOfBlocks'} uncles: $lastXBlocks[$i]{'uncles'}  \n";
	  # print $fh "TimeStamp: $while_tstmp timeframe: $lastXBlocks[$i]{'timeFrame'} blocks:  $lastXBlocks[$i]{'noOfBlocks'} uncles: $lastXBlocks[$i]{'uncles'}  \n";
	# }
	#alina end new
	
	$specific_order	= get_specific_order_hash();
	if ( $currentHighSpeed == 1 )
	{
		print "keep_price_to_min \n";
		keep_price_to_min(\%$specific_order);	
	}
	else
	{
		print "just decrease_price \n";	
		decrease_price();
		
		decrease_speed();
	}

	print "$while_tstmp $specific_order->{'id'} $specific_order->{'price'} $specific_order->{'accepted_speed'} $specific_order->{'limit_speed'} $specific_order->{'workers'}\n";
	print $fh "$while_tstmp $specific_order->{'id'} $specific_order->{'price'} $specific_order->{'accepted_speed'}  $specific_order->{'limit_speed'} $specific_order->{'workers'}\n";		

	
	
	if ($decline_price_int > 0 )
	{
		$decline_price_int--;
	}	
	
	print "Stop ".timestamp()."\n";	
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

sub timestamp {
   my $t = localtime;
   return sprintf( "%04d-%02d-%02d_%02d-%02d-%02d",
                  $t->year, $t->mon + 1, $t->mday,
                  $t->hour, $t->min, $t->sec );
	# %Y-%m-%d_%H-%M-%S				  
	# return localtime;
}
sub keep_price_to_min {
	my $local_specific_order = shift;
	$decoded_json = get_json( "https://api.nicehash.com/api?method=orders.get&location=0&algo=$algo" );
	#print Dumper $decoded_json;
	#print ref($decoded_json->{'result'}->{'orders'});
	my $min_price = 1000000;
	my $min_fixed_price = 1000000; 
	my @active_orders;

	
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
		}
	}
	print "\nTIMESTAMP ".timestamp()." min price: $min_price\n";

    # print "local_specific_order $local_specific_order->{'id'} $local_specific_order->{'price'}\n ";
	
	if ( $target_order == 0 )
	{
		return;
	}
	# don't go higher then 0.700
	if ( $min_price <= 0.0700 )
	{
		$target_price = $min_price + 0.0002;
		if ( $local_specific_order->{'price'} > $target_price )
		{
			#decrease
			if ( ($local_specific_order->{'price'} - $target_price ) > 0.0002 )
			{
				print timestamp()." DOWN  ".($local_specific_order->{'price'} - $target_price)." $local_specific_order->{'price'} $target_price $min_price\n";
				#decrese speed
				decrease_price();
			}
			else
			{
				print timestamp()." Could go DOWN ".($local_specific_order->{'price'} - $target_price)." $local_specific_order->{'price'} $target_price $min_price\n";

			}
		}
		else
		{
			#increase
			if ($local_specific_order->{'price'} < $target_price )
			{
				my $increase_price = 0;
				
				if ($target_price - $local_specific_order->{'price'} > 0.0010 )
				{
					#increase direct
					$increase_price = $target_price;
				}
				else
				{
					#increase incremental					
					$increase_price = $local_specific_order->{'price'} +  0.0001;
				}

				print timestamp()." UP  ".($local_specific_order->{'price'} - $target_price)." $local_specific_order->{'price'} $target_price $min_price\n";
				#print "to increase \n";
				
				print "increase price to $increase_price \n";
				$decoded_json=get_json("https://api.nicehash.com/api?method=orders.set.price&id=$apiid&key=$apikey&location=0&algo=$algo&order=$local_specific_order->{'id'}&price=$increase_price");
				#print Dumper $decoded_json;		
				
				
			}
			else
			{
				#constant
				print timestamp()." CONST  ".($local_specific_order->{'price'} - $target_price)." $local_specific_order->{'price'} $target_price $min_price\n";
				# if ($local_specific_order->{'workers'} == 0 )
				# {
					# my $increase_price = $local_specific_order->{'price'} +  0.0001;
					# print "special condition increase price with $increase_price \n";
					# $decoded_json=get_json("https://api.nicehash.com/api?method=orders.set.price&id=$apiid&key=$apikey&location=0&algo=$algo&order=$local_specific_order->{'id'}&price=$increase_price");
					#print Dumper $decoded_json;		
					
				# }
			}
		}
	}
	
}

sub count_blocks_tick {
	my @uncheck_blocks;
	@uncheck_blocks = `./monitor_ether.pl`;
	foreach (@uncheck_blocks)
	{
		#get timestamp uncles and order id
		chomp($_);
		#print " line [$_] \n";
		if ( $_ =~ /(.*?)#(.*?)#(.*)/ )
		{
			#[2017-06-29_09-43-51] [Uncles Reward: 3.125 Ether (1 Uncle at [46]Position 0)]  [3946512]
			my $tstmp = trim($1);
			my $uncles = trim($2);
			my $block_id = trim($3);
			print "[$tstmp] [$uncles]  [$block_id] \n";			
			# my @block_uncle = ( $block_id , $uncles );
			# if (exists $total_blocks{$tstmp})
			# {
				# print "Multiple $tstmp \n";
			# }
			# else
			# {
				# print "Once $tstmp \n";
				# $total_blocks{$tstmp} = [ @block_uncle ]; 
			# }
			my $nb_uncles = 0;			
			if ( $uncles =~ /.*\((\d*?) Uncle.*?at.*/ )
			{
				$nb_uncles = $1;
			}
			#print "[$tstmp]#[$block_id]#[$nb_uncles] \n";
			processLogEntry("$tstmp#$block_id#$nb_uncles");
			
			# print "[$tstmp] [$uncles]  [$block_id] \n";
			#my ($timestamp) = /(^\d+-\d+-\d+_\d\d:\d\d:\d\d)/;
			#my $t = Time::Piece->strptime($timestamp, $format);
			#print if $t >= $start && $t <= $end;
		}
	}
}

sub trim {
	my $input = shift;
	$input =~ s/^\s+|\s+$//g;
	return $input;
}


#alina GLOBALE#

sub getTimeIndexes{
  my $_timePrm = shift;
  my $_AI = shift;
  my $_HI = shift;
  
  # my $time = Time::Piece->strptime($_timePrm,'%a %b %d %H:%M:%S %Y');
  my $time = Time::Piece->strptime($_timePrm,'%Y-%m-%d_%H-%M-%S');
  
  $$_AI = $time->strftime("%H");
  $$_HI = 0;
  {
	use integer;
	my $minute = $time->strftime("%M");
	$$_HI = ($minute+0)/10;
  }  
}
sub getPreviousIndex{
  my $crtAI = shift;
  my $crtHI = shift;
  my $prevAI = shift;
  my $prevHI = shift;

  $$prevAI = 0;
  $$prevHI = 0;
 
  if ($crtHI == 0)
  {
    $$prevHI = 5;  
    $$prevAI = $crtAI - 1;
  }
  else
  {
    $$prevHI = $crtHI - 1;  
    $$prevAI = $crtAI;
  } 
}

sub processLogEntry
{
  my ($_message) = @_;

  #printf("MESSAGE: %s\n",$_message);

  my (@words) = split /#/, $_message;
  my $timeStamp = $words[0];
  my $blockID = $words[1];
  my $uncles = $words[2];
  
  #printf("time %s\n",$timeStamp);
 
  my $AI = 0;
  my $HI = 0;
  getTimeIndexes($timeStamp,\$AI,\$HI);

  if (!defined $_24HrsBlocks[$AI]{$HI}{$blockID})
  {
    $_24HrsBlocks[$AI]{$HI}{$blockID} = $uncles;
  }
}

sub getPrevious{
  my ($noOfTF) = @_;
  my $crtTime = localtime;
  $crtTime = Time::Piece->strptime($crtTime,'%a %b %d %H:%M:%S %Y');
  my $frmtCrtTime = $crtTime->strftime("%Y-%m-%d_%H-%M-%S");
  my $HI = 0;
  my $AI = 0;  
  my $pHI = 0;
  my $pAI = 0;
  
  getTimeIndexes($frmtCrtTime,\$AI,\$HI);
  getPreviousIndex($AI,$HI,\$pAI,\$pHI);
  
  print " ===> we start with AI $pAI and HI $pHI\n";
  
  @lastXBlocks = ();
  my $noOfChunks = 0;
  my $noOfBlocks = 0;
  my $noOfUncles = 0;
  my $niceKey = '';

  while (  $noOfChunks < $noOfTF )
  {
      #print "chunkNo $noOfChunks AI $ai HI $hi\n";
      #print Dumper $_24HrsBlocks[$ai]{$hi};
      
      my $low = $pHI*10;
      my $high = ($pHI+1)*10 -1;
      $niceKey = sprintf("%02s:%02s:00-%02s:%02s:59",$pAI,$low,$pAI,$high);
    
      my $noOfBlocks = 0;
      my $noOfUncles = 0;
    
      #print "niceKey is $niceKey chunkNo is $noOfChunks \n";
      #$lastXBlocks[$noOfChunks]{$niceKey} = {};
      
      $lastXBlocks[$noOfChunks]{'timeFrame'} = $niceKey;
      $lastXBlocks[$noOfChunks]{'blocks'} = {};
      foreach my $id (keys %{$_24HrsBlocks[$pAI]{$pHI}})
      {
	$lastXBlocks[$noOfChunks]{'blocks'}{$id} = $_24HrsBlocks[$pAI]{$pHI}{$id};
	$noOfBlocks = $noOfBlocks + 1;
	$noOfUncles = $noOfUncles + $_24HrsBlocks[$pAI]{$pHI}{$id};
      }
      
      $lastXBlocks[$noOfChunks]{'noOfBlocks'} = $noOfBlocks;
      $lastXBlocks[$noOfChunks]{'uncles'} = $noOfUncles;
      $noOfChunks = $noOfChunks + 1;
      $AI = $pAI;
      $HI = $pHI;
      getPreviousIndex($AI,$HI,\$pAI,\$pHI);
  }
  
    
}

sub getCrt{

  #my %crtBlocks = ();

  my $HI = 0;
  my $AI = 0; 
  
  %crtBlocks = ();
  
  my $noOfBlocks = 0;
  my $noOfUncles = 0;
      
  my $crtTime = localtime;
  $crtTime = Time::Piece->strptime($crtTime,'%a %b %d %H:%M:%S %Y');
  my $frmtCrtTime = $crtTime->strftime("%Y-%m-%d_%H-%M-%S");
   
  getTimeIndexes($frmtCrtTime,\$AI,\$HI);
  
  my $low = $HI*10;
  my $high = ($HI+1)*10 -1;
  my $niceKey = sprintf("%02s:%02s:00-%02s:%02s:59",$AI,$low,$AI,$high);
  $crtBlocks{'timeFrame'} = $niceKey;
  $crtBlocks{'blocks'} = {};
  if (defined $_24HrsBlocks[$AI])
  {
    #print Dumper $_24HrsBlocks[$AI]{$HI};
    
    foreach my $id (keys %{$_24HrsBlocks[$AI]{$HI}})
    {
      $crtBlocks{'blocks'}{$id}=$_24HrsBlocks[$AI]{$HI}{$id};
      $noOfBlocks = $noOfBlocks + 1;
      $noOfUncles = $noOfUncles + $_24HrsBlocks[$AI]{$HI}{$id};      
    }
  }
  $crtBlocks{'noOfBlocks'} = $noOfBlocks;
  $crtBlocks{'uncles'} = $noOfUncles;
  #print "$noOfBlocks and $noOfUncles \n  ";
  #return \%crtBlocks;
  #return %crtBlocks;
}


sub decrease_price
{
	# if ( $decline_price_int == 0 )
	{
		$decoded_json=get_json("https://api.nicehash.com/api?method=orders.set.price.decrease&id=$apiid&key=$apikey&location=0&algo=$algo&order=$target_order");
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

sub decrease_speed
{
	$decoded_json=get_json("https://api.nicehash.com/api?method=orders.set.limit&id=$apiid&key=$apikey&location=0&algo=$algo&order=$target_order&limit=$min_speed");
}

sub increase_speed
{
	$decoded_json=get_json("https://api.nicehash.com/api?method=orders.set.limit&id=$apiid&key=$apikey&location=0&algo=$algo&order=$target_order&limit=$max_speed");
}

sub get_specific_order_hash
{
	$decoded_json = get_json( "https://api.nicehash.com/api?method=orders.get&my&id=$apiid&key=$apikey&key&location=0&algo=$algo" );	
	my $date_unformated = $decoded_json->{'result'}->{'timestamp'};
	$date= `date --date=\@$date_unformated`;
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


sub read_monitor_ether_log
{
	my @uncheck_blocks;
	@uncheck_blocks = `cat ./monitor_ether_log.txt | grep "\s*2017" | grep -v "Nanopool" | sort | uniq | tail -40`;
	foreach (@uncheck_blocks)
	{
		#get timestamp uncles and order id
		chomp($_);
		#print " line [$_] \n";
		if ( $_ =~ /(.*?)#(.*?)#(.*)/ )
		{
			#[2017-06-29_09-43-51] [Uncles Reward: 3.125 Ether (1 Uncle at [46]Position 0)]  [3946512]
			my $tstmp = trim($1);
			my $uncles = trim($2);
			my $block_id = trim($3);
			print "[$tstmp] [$uncles]  [$block_id] \n";			
			# my @block_uncle = ( $block_id , $uncles );
			# if (exists $total_blocks{$tstmp})
			# {
				# print "Multiple $tstmp \n";
			# }
			# else
			# {
				# print "Once $tstmp \n";
				# $total_blocks{$tstmp} = [ @block_uncle ]; 
			# }
			# my $nb_uncles = 0;			
			# if ( $uncles =~ /.*\((\d*?) Uncle.*?at.*/ )
			# {
				# $nb_uncles = $1;
			# }
			#print "[$tstmp]#[$block_id]#[$nb_uncles] \n";
			processLogEntry("$tstmp#$block_id#$uncles");
			
			# print "[$tstmp] [$uncles]  [$block_id] \n";
			#my ($timestamp) = /(^\d+-\d+-\d+_\d\d:\d\d:\d\d)/;
			#my $t = Time::Piece->strptime($timestamp, $format);
			#print if $t >= $start && $t <= $end;
		}
	}
}

close $fh;
