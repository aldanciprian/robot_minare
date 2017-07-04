#!/usr/bin/perl 

use LWP::Simple;                # From CPAN
use JSON qw( decode_json );     # From CPAN
use Data::Dumper;               # Perl core module
use strict;                     # Good practice
use warnings;                   # Good practice
use Time::localtime;
use Time::Piece;


sub read_monitor_ether_log;
sub getTimeIndexes;
sub getPreviousIndex;
sub processLogEntry;
sub getPrevious;
sub getCrt;
sub trim;

#alina GLOBALE#
my @_24HrsBlocks = ();
my %crtBlocks =();
my @lastXBlocks =();

#init
#init 24HRS array
for my $j (0..23)
{
	for my $k (0..5)
	{
	  $_24HrsBlocks[$j]{$k}= {};
	}
}

read_monitor_ether_log();



#alina new
my $noOfPrevTimeFrames = 100;
getPrevious($noOfPrevTimeFrames);
for my $i (0..($noOfPrevTimeFrames-1))
{
	my %timestamps;
	 # print Dumper $lastXBlocks[$i];
	print "timeframe: $lastXBlocks[$i]{'timeFrame'} blocks:  $lastXBlocks[$i]{'noOfBlocks'} uncles: $lastXBlocks[$i]{'uncles'} - \n";
	foreach (sort (keys (%{$lastXBlocks[$i]{'blocks'}})))
	{
		my %block = %{$lastXBlocks[$i]{'blocks'}{$_}};
		#print "$_  $block{'timeStamp'}  \n";
	 # print Dumper $_;
		$timestamps{$block{'timeStamp'}} = $_;
	}
	 foreach ( sort ( keys %timestamps  ) )
	 {
		 print "$_ $timestamps{$_} \n";
	 }
	print "\n";
}
#alina end new






sub read_monitor_ether_log
{
	my @uncheck_blocks;
	@uncheck_blocks = `cat ./monitor_ether_log.txt | grep "2017" | grep -v "Nanopool" | sort | uniq `;
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
			processLogEntry("$tstmp#$block_id#$uncles");
		}
	}
	@uncheck_blocks = `cat ./monitor_ether_loop_log.txt | grep "2017" | grep -v "Nanopool" | sort | uniq `;
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
			processLogEntry("$tstmp#$block_id#$uncles");
		}
	}
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

  my $crtTime = localtime;
  $crtTime = Time::Piece->strptime($crtTime,'%a %b %d %H:%M:%S %Y');
  
  #printf("time %s\n",$timeStamp);
 
  my $AI = 0;
  my $HI = 0;
  getTimeIndexes($timeStamp,\$AI,\$HI);

  $timeStamp=Time::Piece->strptime($timeStamp,'%Y-%m-%d_%H-%M-%S');
  
  my $crtDay = $crtTime->strftime("%d");
  my $tsDay = $timeStamp->strftime("%d");
  
  if ($crtDay eq $tsDay)
  {
	if (!defined $_24HrsBlocks[$AI]{$HI}{$blockID})
	{
		$_24HrsBlocks[$AI]{$HI}{$blockID}{'timeStamp'} = $timeStamp;
		$_24HrsBlocks[$AI]{$HI}{$blockID}{'uncles'}= $uncles;
	}
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
	$lastXBlocks[$noOfChunks]{'blocks'}{$id}{'uncles'} = $_24HrsBlocks[$pAI]{$pHI}{$id}{'uncles'};
	$noOfBlocks = $noOfBlocks + 1;
	$noOfUncles = $noOfUncles + $_24HrsBlocks[$pAI]{$pHI}{$id}{'uncles'};
	$lastXBlocks[$noOfChunks]{'blocks'}{$id}{'timeStamp'} = $_24HrsBlocks[$pAI]{$pHI}{$id}{'timeStamp'};
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
      $crtBlocks{'blocks'}{$id}{'uncles'}=$_24HrsBlocks[$AI]{$HI}{$id}{'uncles'};
      $noOfBlocks = $noOfBlocks + 1;
      $noOfUncles = $noOfUncles + $_24HrsBlocks[$AI]{$HI}{$id}{'uncles'};
      $crtBlocks{'blocks'}{$id}{'timeStamp'}=$_24HrsBlocks[$AI]{$HI}{$id}{'timeStamp'};
    }
  }
  $crtBlocks{'noOfBlocks'} = $noOfBlocks;
  $crtBlocks{'uncles'} = $noOfUncles;
  #print "$noOfBlocks and $noOfUncles \n  ";
  #return \%crtBlocks;
  #return %crtBlocks;
}

sub trim {
	my $input = shift;
	$input =~ s/^\s+|\s+$//g;
	return $input;
}
