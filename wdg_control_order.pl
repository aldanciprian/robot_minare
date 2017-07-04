#!/usr/bin/perl 
use Data::Dumper;               # Perl core module
use strict;                     # Good practice
use warnings;                   # Good practice
use Time::localtime;
use Time::Piece;


my $sleep_intv = 10;

sub timestamp;

while (1)
{
	my $filename = 'wdg_control_order.txt';
	open(my $fh, '<', $filename) or die "Could not open file '$filename' $!";
	my $last_line;
	$last_line = $_,while (<$fh>);
	close $fh;

	chomp($last_line);


	my $lastTime =  Time::Piece->strptime($last_line,'%Y-%m-%d_%H-%M-%S');
	my $crt_time = timestamp();
	my $crtTime = Time::Piece->strptime($crt_time,'%Y-%m-%d_%H-%M-%S');


	my $delta = $crtTime - $lastTime;
	print "[$crt_time] - [$last_line] $delta \n";

	if ( ($crtTime - $lastTime) > 40 )
	{
		# the last line written by was 40 sec ago.Its to late
		# restart the control_order script
		 print "kill control order becuase distance to the last time is $delta seconds \n";
		 my $pid = `ps -ef | grep control_order.pl | grep -v grep | awk '{print \$2}'`;
		 print "pid to kill is $pid \n";
		 `kill -9 $pid`;
	}
	sleep $sleep_intv;
}
sub timestamp {
   my $t = localtime;
   return sprintf( "%04d-%02d-%02d_%02d-%02d-%02d",
                  $t->year, $t->mon + 1, $t->mday,
                  $t->hour, $t->min, $t->sec );
}