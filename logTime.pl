#!/usr/bin/perl 

use Data::Dumper;               # Perl core module
use strict;                     # Good practice
use warnings;                   # Good practice
use Time::localtime;
use Time::Piece;


#alina GLOBALE#
my @_24HrsBlocks = ();
my %crtBlocks =();
my @lastXBlocks =();


#init 24HRS array
for my $j (0..23)
{
for my $k (0..5)
{
  $_24HrsBlocks[$j]{$k}= {};
}
}

#alina GLOBALE#

sub getTimeIndexes{
  my $_timePrm = shift;
  my $_AI = shift;
  my $_HI = shift;
  
  my $time = Time::Piece->strptime($_timePrm,'%a %b %d %H:%M:%S %Y');
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
  my $HI = 0;
  my $AI = 0;  
  my $pHI = 0;
  my $pAI = 0;
  
  getTimeIndexes($crtTime,\$AI,\$HI);
  getPreviousIndex($AI,$HI,\$pAI,\$pHI);
  
  print " ===> we start with AI $pAI and HI $pHI\n";
  
  @lastXBlocks = ();
  my $noOfChunks = 0;
  my $niceKey = '';

  while (  $noOfChunks < $noOfTF )
  {
      #print "chunkNo $noOfChunks AI $ai HI $hi\n";
      #print Dumper $_24HrsBlocks[$ai]{$hi};
      
      my $low = $pHI*10;
      my $high = ($pHI+1)*10 -1;
      $niceKey = sprintf("%02s:%02s:00-%02s:%02s:59",$pAI,$low,$pAI,$high);
      
      #print "niceKey is $niceKey chunkNo is $noOfChunks \n";
      $lastXBlocks[$noOfChunks]{$niceKey} = {};
      
      foreach my $id (keys %{$_24HrsBlocks[$pAI]{$pHI}})
      {
        $lastXBlocks[$noOfChunks]{$niceKey}{$id} = $_24HrsBlocks[$pAI]{$pHI}{$id};
      }
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

  my $crtTime = localtime;
  getTimeIndexes($crtTime,\$AI,\$HI);
  
  if (defined $_24HrsBlocks[$AI])
  {
    #print Dumper $_24HrsBlocks[$AI]{$HI};
    
    foreach my $id (keys %{$_24HrsBlocks[$AI]{$HI}})
    {
      $crtBlocks{$id}=$_24HrsBlocks[$AI]{$HI}{$id};
    }
  }
  #return \%crtBlocks;
  #return %crtBlocks;
}

my @Messages = ('Thu Jun 22 11:06:39 2017#1#3', 'Thu Jun 22 14:08:30 2017#2#7','Thu Jun 22 11:09:41 2017#2#5',
'Thu Jun 22 12:44:39 2017#1#3', 'Thu Jun 22 12:05:30 2017#3#7','Thu Jun 22 12:09:41 2017#4#5',
'Thu Jun 22 13:56:39 2017#bl1#3', 'Thu Jun 22 13:51:30 2017#bl3#7','Thu Jun 22 14:09:41 2017#bl4#5',
'Thu Jun 22 13:36:39 2017#bl01#5', 'Thu Jun 22 13:35:30 2017#bl103#77',
'Thu Jun 22 14:12:39 2017#bl01343#5','Thu Jun 22 14:32:39 2017#bl0qw2#6','Thu Jun 22 14:32:39 2017#bl0qw2#10',
'Thu Jun 22 14:32:39 2017#bl01#5','Thu Jun 22 14:32:39 2017#bl02#6',

);

foreach my $message (@Messages)
{
  processLogEntry($message);	
}

#print Dumper @_24HrsBlocks;

#getCrt();
#print Dumper %crtBlocks;

getPrevious(6);
print Dumper @lastXBlocks;
