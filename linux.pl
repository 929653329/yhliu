#!/usr/bin/perl -w
use strict;

my $n = 1;
my $line;
my $time;
my $running;
my $stopped;
my $zombie;
my $us;
my $sy;
my $ni;
my $id;
my $mem_total;
my $mem_free;
my $mem_used;
my $mem_buff;
my $io;
my %hash_user_virt;
my %hash_user_res;
my %hash_user_cpu;
my %hash_user_mem;
my @who;
my $user_num;
open TOP,"top -b -n 1|"or die $!;

while(<TOP>)
{
	chomp;
	$line = $_;
	if($n == 1)
	{
		my @line = split(" ",$line);
		$time = $line[2];
	}
	elsif($n == 2)
	{
		my @line = split(" ",$line);
		$running = $line[3];
		$stopped = $line[7];
		$zombie  = $line[9];
	}
	elsif($n == 3)
	{
		if($line=~/%Cpu\(s\):(.*)us,(.*)sy,(.*)ni,(.*)id/)
		{
			$us = $1;
			$sy = $2;
			$ni = $3;
			$id = $4;
		}
	}
	elsif($n == 4)
	{
		if($line=~/:(.*)k total,(.*)k free,(.*)k used,(.*)k buff/)
		{
			$mem_total = $1*1024;
			$mem_free = $2*1024;
			$mem_used = $3*1024;
			$mem_buff = $4*1024;
		}
		elsif($line=~/:(.*) total,(.*) free,(.*) used,(.*) buff/)
		{
			$mem_total = $1;
			$mem_free = $2;
			$mem_used = $3;
			$mem_buff = $4;
		}
	}
	elsif($n > 7)
	{
		my @line = split(" ",$line);
		if(exists $hash_user_virt{$line[1]})
		{
			$hash_user_virt{$line[1]} += $line[5];
		}
		else
		{
			$hash_user_virt{$line[1]} = $line[5];
		}
		
		if(exists $hash_user_res{$line[1]})
		{
			$hash_user_res{$line[1]} += $line[5] + $line[6];
		}
		else
		{
			$hash_user_res{$line[1]} = $line[5] + $line[6];
		}
		
		if(exists $hash_user_cpu{$line[1]})
		{
			$hash_user_cpu{$line[1]} += $line[8];
		}
		else
		{
			$hash_user_cpu{$line[1]} = $line[8];
		}
		
		if(exists $hash_user_mem{$line[1]})
		{
			$hash_user_mem{$line[1]} += $line[9];
		}
		else
		{
			$hash_user_mem{$line[1]} = $line[9];
		}
	}
	$n++;
}
close TOP;


open IOSTAT,"iostat -x|"or die $!;

while(<IOSTAT>)
{
	if(/Device/)
	{
		my $iostat = <IOSTAT>;
		chomp($iostat);
		$io = (split(" ",$iostat))[13];
	}
}

close IOSTAT;

open WHO,"who|awk '{print \$1}'|"or die $!;
while(<WHO>)
{
	chomp;
	push(@who,$_);
}
close WHO;

$user_num = $#who + 1;

printf("%s|%s|%s|%s|%.1f|%.1f|%.1f|%.1f|%d|%d|%d|%d|%.2f|",$time,$running,$stopped,$zombie,$us,$sy,$ni,$id,$mem_total,$mem_free,$mem_used,$mem_buff,$io);

my @keys = keys %hash_user_virt;
printf("%d|",$#keys+1);
foreach my $key (@keys)
{
	printf("%s|%d|",$key,$hash_user_virt{$key});
	printf("%d|",$hash_user_res{$key});
	printf("%.1f|",$hash_user_mem{$key});
	printf("%.1f|",$hash_user_cpu{$key});
}

printf("%d|",$user_num);
foreach my $user (@who)
{
	printf("%s|",$user);
}

