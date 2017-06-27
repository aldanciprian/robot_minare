#!/usr/bin/perl 

### alina
BEGIN {
use File::Basename;
use Cwd 'realpath';
my $dirname = dirname(realpath(__FILE__));

          unshift @INC, "$dirname/";
          unshift @INC, "$dirname/PerlModules";
          }
use Spreadsheet::ParseExcel;
use Spreadsheet::ParseExcel::SaveParser;
use List::MoreUtils 'any';
### alina

use LWP::Simple;                # From CPAN
use JSON qw( decode_json );     # From CPAN
use Data::Dumper;               # Perl core module
use strict;                     # Good practice
use warnings;                   # Good practice
use Time::localtime;



### alina
my $filename='perl.xls';
my $excelFile;
my $excelParser;
my $crtWrksheet;
my $lastTimeStamp='';
#column index for ID
my %Index_Of = ();
$Index_Of{'MinPrice'} = 1;
my @SheetSet = qw(Price Speed Miners);
my %newIDSet =();
$newIDSet{'MinPrice'} = 1;
my @nonExistingIDs =();
### alina



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
sub follow_others;

### alina
#citire la startup
#@param file name
sub initExcelParamsStartup{
  $excelFile   = Spreadsheet::ParseExcel::SaveParser->new();
  $excelParser = $excelFile->Parse($filename);

  #startReading from firstSheet
  if (defined $excelParser)
  {
    $crtWrksheet = $excelParser->worksheet(0);
    if (defined $crtWrksheet)
    {
       my $row = 1 ;
       my $cell = $crtWrksheet->get_cell($row,0);
       if (defined $cell)
       {	
   	  my $TS = $cell->value;
   	  #printf( "timeStamp is %s \n",$TS);
   	  $lastTimeStamp = $TS;

    	  for my $col(0..$crtWrksheet->col_range)
    	  {
    		my $cell = $crtWrksheet->get_cell(0,$col);
    		next unless $cell;
    		my $orderID = $cell->value;

    		##here I am getting a problem##
		$Index_Of{$orderID} = $col;
		$newIDSet{$ID} = $col;
    		#printf( "IndexOf %s = > %d  \n",$orderID,$Index_Of{$orderID});
	   }
       }
    }
  }
  else
  {
	my $workbook  = Spreadsheet::WriteExcel->new($filename);
	foreach my $sheet (@SheetSet)
	{	
		$crtWrksheet = $workbook->add_worksheet($sheet);
		$crtWrksheet->write(0,1,'MinPrice');

	}
	$workbook->close;
	$excelParser = $excelFile->Parse($filename);
  }
}

sub processMessage{
  my ($message) = @_;
  my (@words) = split /#/, $message;
  my $timeStamp = $words[0];
  my $sheetID = $words[1];
  my $ID = $words[2];
  my $value = $words[3];
  
  $crtWrksheet = $excelParser->worksheet($sheetID);
  
  if (!defined $crtWrksheet)
  {
    #create worksheet
    $crtWrksheet = $excelParser->AddWorksheet($sheetID);
  }
  
  if ($lastTimeStamp eq $timeStamp)
  {
    #exiting oderID
    if (!defined $Index_Of{$ID})
    {
		$Index_Of{$ID} = $crtWrksheet->col_range+1;
    }
	else
	{
		$newIDSet{$ID}=1;
	}
    #printf("we have the realOrderIdINDEX %s we will add the value %d\n",$ID,$value);
    #if we don't have the ID yet in this worksheet add it	
    my $orderIDCell = $crtWrksheet->get_cell(0,$Index_Of{$ID});
    if (!defined $orderIDCell)
    {	
	$crtWrksheet -> AddCell(0, $Index_Of{$ID}, $ID);
    }	
    $crtWrksheet -> AddCell($crtWrksheet->row_range+0, $Index_Of{$ID}, $value);
    if ($ID eq 'MinPrice')
    {
       $excelParser->SaveAs($filename);
    }
  }
  else
  {
	#check inexsting IDS
	my @OldIDs = keys %Index_Of;
	@nonExistingIDs = grep ! exists $newIDSet{$_}, @OldIDs;
	
	foreach my $nonId (@nonExistingIDs)
	{
		printf("-----------> remove %s \n",$nonId);
		delete $Index_Of{$nonId};
	}
	$lastTimeStamp = $timeStamp;
	%newIDSet =();
	#newTS #add one new line to each sheet
	foreach my $sheet (@SheetSet)
	{
	  $crtWrksheet = $excelParser->worksheet($sheet);
	  if (!defined $crtWrksheet)
	  {
	    $crtWrksheet = $excelParser->AddWorksheet($sheet);
	    $crtWrksheet->AddCell(0,1,'MinPrice');
	  }
	  $crtWrksheet->AddCell($crtWrksheet->row_range+1, 0, $timeStamp);
	  #printf("add TS value %d,%d,sheet %s\n",$crtWrksheet->row_range+1,0,$sheet);
	}
	#add value and ID if new
	processMessage($message);
  }
}
### alina


### alina
initExcelParamsStartup();
### alina
while (1) 
{
	print "============================= FOLLOW NANOPOOL ".timestamp()."  $$ ======================\n";
	follow_others();
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
sub follow_others {
	$decoded_json = get_json( "https://api.nicehash.com/api?method=orders.get&location=0&algo=$algo" );
	#print Dumper $decoded_json;
	#print ref($decoded_json->{'result'}->{'orders'});
	my $min_price = 1000000;
	my $min_fixed_price = 1000000; 
	my $specific_order;
	my $tstmp = timestamp();
	# fake minprice messaj
	print "\nTIMESTAMP START".timestamp()."\n";
	foreach (@{$decoded_json->{'result'}->{'orders'}})
	{

		#if ( $_->{'alive'} == 1 )
		{	
			#if ( $_->{'type'} == 1 )
			#{
				#if ( $min_fixed_price > $_->{'price'} )
				#{
					#$min_fixed_price = $_->{'price'};
				#}
			#}

			# print $_->{'id'}."\t";
			# print $_->{'type'}."\t";
			# print $_->{'workers'}."\t";
			# print $_->{'price'}."\t";	
			# print $_->{'limit_speed'}."\t";			
			# print $_->{'accepted_speed'}."\n";	
			# get the minimum price where is mining for standard;
			if ( $_->{'type'} == 0 )
			{
				#if ( $_->{'accepted_speed'} > 0 )
				if ( $_->{'workers'} > 0 )
				{
					if ( $min_price > $_->{'price'} )
					{
						$min_price = $_->{'price'};
					}
				}
				#print "$_->{'id'}\t$_->{'price'}\t$_->{'limit_speed'}\t$_->{'workers'}\t$_->{'accepted_speed'} \n";					
				print "$tstmp#$_->{'id'}#$_->{'price'}\n";					
				# send to excel this order 
				processMessage("$tstmp#Price#$_->{'id'}#$_->{'price'}");
				processMessage("$tstmp#Speed#$_->{'id'}#$_->{'limit_speed'}");
				processMessage("$tstmp#Miners#$_->{'id'}#$_->{'workers'}");
				#processMessage("Thu Jun 22 14:06:39 2017#MinPrice#0.01");
				#processMessage("Thu Jun 22 14:06:39 2017#1234567#0.01");
				#processMessage("Thu Jun 22 14:06:39 2017#11102#7");
			}
			else
			{
				print "$tstmp#TYPE $_->{'type'}#$_->{'id'}#$_->{'price'}\n";	
			}
		}
	}

	#print "\nTIMESTAMP $tstmp min price: $min_price\n";
	#real mesaj
	processMessage("$tstmp#Price#MinPrice#$min_price");
	print "\nTIMESTAMP STOP".timestamp()."\n";
}
