#! /usr/bin/perl -w

use strict;
use warnings;
use Time::localtime;
use Tie::File;

my $path_to_log="/var/log/frox.log";
my $yesterday = localtime(time()-24*60*60);
my @days = qw( Sun Mon Tue Wed Thu Fri Sat );
my @month =  qw( Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec );
my $regexp_beg = sprintf("%03s %03s %02d", $days[$yesterday->wday], $month[$yesterday->mon], $yesterday->mday);
my $regexp_end = sprintf("%04d", $yesterday->year+1900);

#print $days[6]."\n";
#print $yesterday->wday."\n";
#print $regexp_beg.$regexp_end."\n";

my $postfix=`date -v -1d "+%Y-%m-%d"`;

tie (my @arr_str, 'Tie::File', $path_to_log) or die ("Can't open file! $!\n");

sub parse_frox_log
{
        my @mas=@_;
        my %what_download;
        #print scalar @mas."\n";
        for (my $i=0; $i<scalar(@mas); $i++)
        {
                if ($mas[$i] =~ /^$regexp_beg\s+\d+\:\d+\:\d+\s+$regexp_end\s+\w+\[\d+\]\s+Real\s+address\s+\=\s+(\d+\.\d+\.\d+\.\d+)/)
                {
                        my $tmp=$1;
                        for (my $j=$i+1; $j<scalar(@mas); $j++)
                        {
                                #print $mas[$j];
                                if ($mas[$j] =~ /^$regexp_beg\s+\d+\:\d+\:\d+\s+$regexp_end\s+\w+\[\d+\]\s+C\:\s+RETR\s+([\w\d\W\D\s]+)/)
                                {
                                        $what_download{$1}=$tmp;
                                }
                                elsif ($mas[$j] =~ /^($regexp_beg\s+\d+\:\d+\:\d+\s+$regexp_end)\s+\w+\[\d+\]\s+Real\s+address\s+=\s+(\d+\.\d+\.\d+\.\d+)/)
                                {
                                        last;
                                }
                        }
                }

        }
        return %what_download;
}

my $name;
my $ip;
my $daybefore=`date -v -1d "+%d-%m-%Y"`;
chomp($daybefore);

format FH =
|   @<<<<<<<<<<          |   @<<<<<<<<<<<<<<<    |@<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<...|                                                        
    $daybefore               $ip                  $name
------------------------------------------------------------------------------------------------------------
.

my %data = parse_frox_log(@arr_str);
#gen_report(%data);
my %arr;
my $val;
open (FH, ">/var/log/js_script_exec_log/frox_stat/stat.$postfix");
print FH "
JS REPORT, frox statistic!
------------------------------------------------------------------------------------------------------------
|      Date              |            IP         |                        File Name                        |
------------------------------------------------------------------------------------------------------------
";
foreach $val (keys %data)
{
	$name=$val;
	$ip=$data{$val};
	write FH;
}
close(FH);


