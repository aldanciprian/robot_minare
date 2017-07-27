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
my $target_price = 0; #current target price
my $blocks_threshold = 1; #threshold for number of blocks from start of timeframe
my $currentHighSpeed = 0; # on off for current mining highSpeed
my $delayCurrentHighSpeed = 0; # delay for on so we can catch de price decrease
my $specific_order; # the hash of the target order	
my $startDiffInt_l1 = 120; # seconds from the start of the timeframe
my $endDiffInt_l1 = 80; #  seconds until the end of the timeframe
my $startDiffInt_l2 = 80; # seconds from the start of the timeframe
my $endDiffInt_l2 = 125; #  seconds until the end of the timeframe
my $startDiffInt_l3 = 126; # seconds from the start of the timeframe
my $endDiffInt_l3 = 140; #  seconds until the end of the timeframe
my $resetDiffInt = 250; # seconds until the end of the timeframe to reset the speed
my $big_speed_ctr = 0; # the counter for the big speed acceleration
my $big_speed_inter = 1; # number of iterations for the big speed the big speed acceleration
my $old_startCrtTF = 0; # the old crt TF 
my $startCycleRef =  900; # seconds from the last of the cycle start
my $maxStartCycle = 5160; # maximum number of seconds to repeat the interval
my $startCycle =  $startCycleRef; # seconds from the last of the cycle start
my $jitterStartCycle = 40; # seconds from the end where we verify is order is stopped
my $increaseStartCycle = 20; # seconds to increase start cycle time in case is not to 0
my $deltaCycleRef =  50; # seconds from the last of the cycle start
my $maxDeltaCycle = 300; # max number of seconds to wait for accepted_speed
my $deltaCycle =  $deltaCycleRef; # seconds from the last of the cycle start
my $jitterDeltaCycle =  30; # seconds from the last of the cycle start
my $increaseDeltaCycle =  15; # seconds from the last of the cycle start
my $tf_valid = 0; # if 1 it means we can mine from the point of view of the TF
my $can_decrease = 0; # says if we are able to decrease instant or not
my $crtMinPrice = 0; # the current MinPrice

my $fh_decrease;
my $decreaseFilename = "control_order_spikes_hash_decrease_success.txt";

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


my $max_speed = 0.2;
my $l1_speed = 0.2;
my $l2_speed = 0.4;
my $l3_speed = 0.8;
my $req_speed = 2;
my $min_speed = 0.1;

#print Dumper decode_json( get( "https://api.nicehash.com/api" ) );


my $filename = 'control_order_spikes_hash_log.txt';
open(my $fh, '>>', $filename) or warn "Could not open file '$filename' $!";




sub net_hastrate_dificulty;
sub get_tstmp;
sub get_hashrate;
sub get_state;


sub shouldMine_HashRate;
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
sub getMinPrice;


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
#read_monitor_ether_log();

open $file_samplings_h, $file_samplings or warn "Could not open $file_samplings: $!";
while( my $line = <$file_samplings_h>)  {   
	chomp($line);
	push @samplings, $line;
	$machine_state = get_state($line);	
}
close $file_samplings_h;



while (1) 
{
	my $tstmp = timestamp();
	my $while_tstmp = timestamp();
	print "============================= FOLLOW NANOPOOL $while_tstmp  $$ ======================\n";
	print "Start $while_tstmp \n";
	
	net_hastrate_dificulty($machine_state);
	
	# watchdog
	my $filename_wdg = 'wdg_control_order_spikes_hash.txt';
	open(my $fh_wdg, '>>', $filename_wdg) or die "Could not open file '$filename_wdg' $!";
	print $fh_wdg "$while_tstmp\n";
	close $fh_wdg;

	$specific_order	= get_specific_order_hash();

	if (defined $specific_order->{'id'} )	
	{
		#we found the target order 
		print "we found the order \n";
		#print " yes target order \n";
	}
	else
	{
		#we didn't found the target order
		#print " no target order \n";
		sleep 10;
		next;		
	}	
		
	
	
	# last start
	my $filename_start = 'start_control_order_spikes_hash.txt';	
	
	#get current time
	my $crtTime =   Time::Piece->strptime($while_tstmp,'%Y-%m-%d_%H-%M-%S');
	
	#open for read last line
	open(my $fh_start, '<', $filename_start) or warn "Could not open file '$filename_start' $!";
	my $last_line;
	$last_line = $_,while (<$fh_start>);
	close $fh_start;
	chomp($last_line);
	
	
	my $startTime = Time::Piece->strptime($last_line,'%Y-%m-%d_%H-%M-%S');	
	
	print "$last_line and $while_tstmp - diff";
	
	my $diffTime = $crtTime - $startTime;
	print " is $diffTime \n";
	
	
	
	#read when was the last decrease_success
	my $last_line_decrease ;
	open(my $fh_decrease, '<', $decreaseFilename) or warn "Could not open file '$decreaseFilename' $!";
	$last_line_decrease = $_,while (<$fh_decrease>);
	close $fh_decrease;
	chomp($last_line_decrease);
	my $decreaseTime = Time::Piece->strptime($last_line_decrease,'%Y-%m-%d_%H-%M-%S');			
			
	my $decrease_delta = $crtTime - $decreaseTime;

	print "last decrease success was $decrease_delta ago \n"; 
	if ( $currentHighSpeed == 0 )
	{
		if ( $decrease_delta > 600 )
		{
			# the last success decrease was more then 10 minutes
			# we can mine if the other conditions are good
			#mine only if the current speed is 0
			if ( ( $specific_order->{'accepted_speed'} == 0 ) && ($specific_order->{'workers'} == 0) )
			{
				my $should_mine = 0;
				$should_mine = shouldMine_HashRate();
				if ( $should_mine == 1 )
				{
					print "Start Mining \n";	
					# open for append last line
					$currentHighSpeed = 1;
					# $startCycle =$startCycleRef;
					open($fh_start, '>>', $filename_start) or die "Could not open file '$filename_start' $!";
					print $fh_start "$while_tstmp\n";
					close $fh_start;		
				}
				else
				{
					print "Hashrate is not dropped enough. Don't mine yet ! \n";
				}
			}
		}	
	}


	

	if ( ( $diffTime < $deltaCycle ) && ( $currentHighSpeed == 1 )	 )
	{

		# it should be in mining here
		$currentHighSpeed = 1;
		print "still mining $diffTime < $deltaCycle \n";
		#if it didn't received speed leave it on a little bit longger
		#check if it has speed
		if ( $specific_order->{'accepted_speed'} == 0 )
		{
			print "Still didn't received speed \n";
			if ( $deltaCycle > $maxDeltaCycle )
			{
				$deltaCycle = $deltaCycleRef;
			}
			else
			{
				$deltaCycle = $deltaCycle + $increaseDeltaCycle;					
			}
		}
		else
		{
			print "It received speed \n";
			$deltaCycle = $deltaCycleRef;
		}			
	}
	else
	{
		# stop mining
		$currentHighSpeed = 0;
		print "stop mining \n";
	}

	getMinPrice();
	

	if ( $currentHighSpeed == 1 )
	{
		print "keep_price_to_min \n";
		print "MINING ! \n";
		keep_price_to_min(\%$specific_order);	
		increase_speed($req_speed,\%$specific_order);		
	}
	else
	{
		print "just decrease_price \n\n";	

		decrease_price(\%$specific_order,0);						
		decrease_speed();
	}

	print "$while_tstmp $specific_order->{'id'} $specific_order->{'price'} -  $specific_order->{'accepted_speed'}  - $specific_order->{'limit_speed'} $specific_order->{'workers'} - MinPrice $crtMinPrice\n";
	print $fh "$while_tstmp $specific_order->{'id'} $specific_order->{'price'} -  $specific_order->{'accepted_speed'}  -  $specific_order->{'limit_speed'} $specific_order->{'workers'} - MinPrice $crtMinPrice\n";		

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
                  $t->year, $t->mon, $t->mday,
                  $t->hour, $t->min, $t->sec );
	# %Y-%m-%d_%H-%M-%S				  
	# return localtime;
}
sub keep_price_to_min {
	my $local_specific_order = shift;
	my $min_price  = $crtMinPrice;
	

	
    # print "local_specific_order $local_specific_order->{'id'} $local_specific_order->{'price'}\n ";
	
	if ( $target_order == 0 )
	{
		return;
	}
	# don't go higher then 0.700
	if ( $min_price <= 0.0700 )
	{
		$target_price = $min_price + 0.0002;
		# $target_price = $min_price - 0.0005;		
		# $target_price = $min_price;
		if ( $local_specific_order->{'price'} > $target_price )
		{
			#decrease
			if ( ($local_specific_order->{'price'} - $target_price ) > 0.0007 )
			{
				print timestamp()." DOWN   $local_specific_order->{'price'} $target_price $min_price\n";
				#decrese speed
				decrease_price(\%$specific_order,0);				
			}
			else
			{
				print timestamp()." Could go DOWN  $local_specific_order->{'price'} $target_price $min_price\n";

			}
		}
		else
		{
			#increase
			if ($local_specific_order->{'price'} < $target_price )
			{
				my $increase_price = 0;
				
				if ($target_price - $local_specific_order->{'price'} > 0.0004 )
				{
					#increase direct
					$increase_price = $target_price;
				}
				else
				{
					#increase incremental					
					$increase_price = $local_specific_order->{'price'} +  0.0001;
				}

				print timestamp()." UP   $local_specific_order->{'price'} $target_price $min_price\n";
				#print "to increase \n";
				
				print "increase price to $increase_price \n";
				$decoded_json=get_json("https://api.nicehash.com/api?method=orders.set.price&id=$apiid&key=$apikey&location=0&algo=$algo&order=$local_specific_order->{'id'}&price=$increase_price");
				#print Dumper $decoded_json;		
				
				
			}
			else
			{
				#constant
				print timestamp()." CONST   $local_specific_order->{'price'} $target_price $min_price\n";
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
	my $local_specific_order = shift;	
	my $force = shift;		
	if ( $target_order != 0 )
	{
		if ( $force == 1 )
		{
			# a force decrease is requested
			$decoded_json=get_json("https://api.nicehash.com/api?method=orders.set.price.decrease&id=$apiid&key=$apikey&location=0&algo=$algo&order=$target_order");
			print Dumper $decoded_json;
			if ( exists $decoded_json->{'result'}->{'success'} )
			{
				print "decrease success \n";
				$decline_price_int = $decline_price_int_limit;
				# mark the momemt de decrease was a success
				open(my $fh_decrease, '>', $decreaseFilename) or die "Could not open file '$decreaseFilename' $!";
				print $fh_decrease timestamp();
				close $fh_decrease;

			}
			else
			{
				print  "decrease error \n";
			}
			
		}
		else
		{
			# normal decrease
			# print "local_specific_order accepted_speed is $local_specific_order->{'accepted_speed'} \n";
			if ( ($local_specific_order->{'accepted_speed'} != 0) || ( $local_specific_order->{'workers'} != 0 ) )
			{
				$decoded_json=get_json("https://api.nicehash.com/api?method=orders.set.price.decrease&id=$apiid&key=$apikey&location=0&algo=$algo&order=$target_order");
				print Dumper $decoded_json;
				if ( exists $decoded_json->{'result'}->{'success'} )
				{
					print "decrease success \n";
					$decline_price_int = $decline_price_int_limit;
					#mark the momemt de decrease was a success
					open(my $fh_decrease, '>', $decreaseFilename) or die "Could not open file '$decreaseFilename' $!";
					print $fh_decrease timestamp();
					close $fh_decrease;

				}
				else
				{
					print  "decrease error \n";
				}
			}
			
			
		}
	}	
}

sub decrease_speed
{
	if ($target_order != 0 )
	{
	$decoded_json=get_json("https://api.nicehash.com/api?method=orders.set.limit&id=$apiid&key=$apikey&location=0&algo=$algo&order=$target_order&limit=$min_speed");	
	}
}

sub increase_speed
{
	my $speed = shift;
	my $local_specific_order = shift;
	if ($target_order != 0 )
	{
		# if ( $local_specific_order->{'accepted_speed'} != 0 )	
		# {
			# $decoded_json=get_json("https://api.nicehash.com/api?method=orders.set.limit&id=$apiid&key=$apikey&location=0&algo=$algo&order=$target_order&limit=$req_speed");		
		# }
		# else
		{
			$decoded_json=get_json("https://api.nicehash.com/api?method=orders.set.limit&id=$apiid&key=$apikey&location=0&algo=$algo&order=$target_order&limit=$speed");		
		}

	}
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
	@uncheck_blocks = `cat ./monitor_ether_log.txt | grep "2017" | grep -v "Nanopool" | sort | uniq | tail -40`;
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
			# print "[$tstmp] [$uncles]  [$block_id] \n";			
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
	
	#monitor_ether_loop_log
	@uncheck_blocks = `cat ./monitor_ether_loop_log.txt | grep "2017" | grep -v "Nanopool" | sort | uniq | tail -40`;
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
			# print "[$tstmp] [$uncles]  [$block_id] \n";			
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

sub getMinPrice
{
	$decoded_json = get_json( "https://api.nicehash.com/api?method=orders.get&location=0&algo=$algo" );
	#print Dumper $decoded_json;
	#print ref($decoded_json->{'result'}->{'orders'});
	my $min_price = 1000000;
	my $min_fixed_price = 1000000; 
	# my @active_orders;

	
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
				# push (@active_orders,$_);			
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
	$crtMinPrice = $min_price;
	# print "MinPrice is $crtMinPrice \n";
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

sub shouldMine_HashRate
{
	my $ret_value = 0;
	my $tstmp = timestamp();
	my $first_tstmp = get_tstmp($samplings[ 0 ]);

	my $last_tstmp = get_tstmp($samplings[ $#samplings - 1]);
	print "first $first_tstmp last $last_tstmp \n";		
	my $firstTime = Time::Piece->strptime($first_tstmp,'%Y-%m-%d_%H-%M-%S');
	my $lastTime = Time::Piece->strptime($last_tstmp,'%Y-%m-%d_%H-%M-%S');
	
	if ( $#samplings < ($samplings_size - 1) )
	{
		print "not enough samplings $machine_state $#samplings\n";
		return $ret_value;
	}
	
	# 50 seconds jitter
	if ( ( $lastTime - $firstTime ) > ( 240 +  50 ) )
	{
		# the window is bigger then 4 min
		print "window longer then 4 min ! - keep sampling ".($lastTime - $firstTime)." \n";
		return $ret_value;
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
			$ret_value = 1 ;
		}
		else
		{
			#not enough decline
			print "not enough decline yet $delta_procent \n";
		}
		
	return $ret_value;
}


close $fh;
