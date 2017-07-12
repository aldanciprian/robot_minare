#!/usr/bin/perl 


use Data::Dumper;               # Perl core module
use strict;                     # Good practice
use warnings;                   # Good practice

my $filename_start = "balance_log.txt";



open(my $fh, '<', $filename_start) or die "Could not open file '$filename_start' $!";
# foreach (my $line = <fh>)  {   
   # print $line;    
	 # if ( $line =~ /^(2017.*?):\s*?0\.(\d+?);\s*?0\.\d+? ;.*/ )
	 # {
			# print "$1 $2 $3\n";
	 
	 # }
# }

while( my $line = <$fh>)  {   
	 # if ( $line =~ /^(2017.*?):\s*?0\.(\d+?);\s*?0\.\d+? ;.*/ )
	 if ( $line =~ /^(2017.*?): (0\.\d+) ; (0\.\d+) .*/ )	 
	 {
			if ( $2 != $3 )
			{
				my $delta  =  $3 * 100;
				print "$1  $2 ".sprintf("%0.15f",$delta)."\n";			
			}

	 
	 }
}
close $fh;


	