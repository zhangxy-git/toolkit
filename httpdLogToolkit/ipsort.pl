#!/usr/bin/perl 
#########################################
#֧��gzipѹ��������־			#
#./ipsort.pl filename 			#
#./ipsort.pl -f filename 		#
#./ipsort.pl -f filename -t hh:mm	#
#./ipsort.pl -f filename -t hh:mm hh:mm	#
#########################################
#use warnings;
#use strict;
use Sys::Hostname;

#������鼰Ԥ����
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

#����ļ���
if ($#LogFile eq 0){
	$LogFile[0]=~m#^.*/([^/]*)_access.*$#;
	our $Vhost=$1;
}
my $Host=hostname;
my $UnixTime=time;
my $Output="ipaddr_${Host}_${Vhost}_$TIME[0]-$TIME[1]_${UnixTime}.txt";
$Output=~s/[-_]+/_/g;
$Output=~s/[^\w.-:]/_/g;

print "����ͳ�ƣ�����ļ���: $Output\n"; 

#����ʱ��β���ѡ���Ӻ���
if($StartMark && $StopMark){
	$CallSub="waitStart";
}elsif($StartMark){
	$CallSub="waitStart2";
}else{
	$CallSub="doCut2";
}

#��ȡ�ļ���Ԥ������IP��ַ���ظ����ֵĴ��������ϣ
#hash�ṹ keys:IP��ַ  values:�ظ����ֵĴ���
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


#��ϣ����ת��������
#����ṹ IP��ַ�ظ����ִ���(TAB�ָ���)IP��ַ
my @Report;
while((my $k,my $v)=each %TH){
	 push  @Report,"$v	$k";
	 delete $TH{$k};
}

#��������
@Report=sort { $a<=>$b } @Report;

#���
open OUT,">","$Output";
while (my $line=(pop @Report)){
	print OUT "$line\n";
}
close OUT;

#��ʱ���ȡ�ļ����õĺ���
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