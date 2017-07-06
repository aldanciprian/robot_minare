#!/usr/bin/perl

use Data::Dumper;               # Perl core module
use strict;                     # Good practice
use warnings;                   # Good practice
use Time::localtime;
use Time::Piece;

my @timeStamps = `cat ./monitor_ether_loop_log.txt  | grep "^\\s*2017" | sort | uniq | awk -F"#" '{print \$1}'`;

my $numOfElements = scalar @timeStamps;

my $ts1 = 0;
my $ts2 = 0;

my $timeDiff = 0;

for my $i (0..$numOfElements-2)
{
  $ts1 = $timeStamps[$i];
  chomp($ts1);
  $ts2 = $timeStamps[$i+1];
  chomp($ts2);

  $ts1 =   Time::Piece->strptime($ts1,'%Y-%m-%d_%H-%M-%S');
  $ts2 = Time::Piece->strptime($ts2,'%Y-%m-%d_%H-%M-%S');
  $timeDiff = $ts2-$ts1;

  print "$ts2 - $ts1 ->  $timeDiff seconds\n";
}

