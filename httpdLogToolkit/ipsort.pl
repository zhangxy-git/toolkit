#!/usr/bin/perl 
#########################################
#支持gzip压缩过的日志			#
#./ipsort.pl filename 			#
#./ipsort.pl -f filename 		#
#./ipsort.pl -f filename -t hh:mm	#
#./ipsort.pl -f filename -t hh:mm hh:mm	#
#########################################
#use warnings;
#use strict;
use Sys::Hostname;

#参数检查及预处理
my $Type="LogFile";
for (@ARGV){
        if(/^-t$/){
                $Type="TIME";
                next;
        }
        if(/^-f$/){
                $Type="LogFile";
                next;
        }
        push @${Type},$_;
}
for(@TIME){
        die "unknown time format $_\n" if!(/^[0-2][0-9]:[0-5][0-9]$/);
}

for(@LogFile){
        die "no such file $_\n" if (!-e $_);
}
my $StartMark=":$TIME[0]:"if($TIME[0]);
my $StopMark=":$TIME[1]:"if($TIME[1]);

#输出文件名
if ($#LogFile eq 0){
	$LogFile[0]=~m#^.*/([^/]*)_access.*$#;
	our $Vhost=$1;
}
my $Host=hostname;
my $UnixTime=time;
my $Output="ipaddr_${Host}_${Vhost}_$TIME[0]-$TIME[1]_${UnixTime}.txt";
$Output=~s/[-_]+/_/g;
$Output=~s/[^\w.-:]/_/g;

print "正在统计，输出文件名: $Output\n"; 

#根据时间段参数选择子函数
if($StartMark && $StopMark){
	$CallSub="waitStart";
}elsif($StartMark){
	$CallSub="waitStart2";
}else{
	$CallSub="doCut2";
}

#截取文件，预处理后将IP地址和重复出现的次数存入哈希
#hash结构 keys:IP地址  values:重复出现的次数
for my $file(@LogFile){
	if($file=~/gz$/){
		open IN,"gzip -dc $file|";
	}else{
		open IN,"$file";
	}
	while(<IN>){
		&$CallSub;
		chomp;
		my ($line)=split;
	 	$TH{$line}++;
	}
	close IN;
}


#哈希数据转存入数组
#数组结构 IP地址重复出现次数(TAB分隔符)IP地址
my @Report;
while((my $k,my $v)=each %TH){
	 push  @Report,"$v	$k";
	 delete $TH{$k};
}

#数组排序
@Report=sort { $a<=>$b } @Report;

#输出
open OUT,">","$Output";
while (my $line=(pop @Report)){
	print OUT "$line\n";
}
close OUT;

#按时间截取文件调用的函数
sub doCut{
	last if(/$StopMark/);
}

sub waitStart{
	$CallSub="doCut" if(/$StartMark/);
	next;
}

sub doCut2{
}

sub waitStart2{
	$CallSub="doCut2" if(/$StartMark/);
	next;
}
