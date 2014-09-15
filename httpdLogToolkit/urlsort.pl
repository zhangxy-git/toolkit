#!/usr/bin/perl 
#########################################
#支持gzip压缩过的日志			#
#./urlsort.pl filename			#
#./urlsort.pl -f filename		#
#./urlsort.pl -f filename -t hh:mm	#
#./urlsort.pl -f filename -t hh:mm hh:mm#
#########################################
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
my $Output="urlsort_${Host}_${Vhost}_$TIME[0]-$TIME[1]_${UnixTime}.txt";
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
		open IN,"gzip -dc $file|" or die "can not open $file";
	}else{
		open IN,"$file" or die "can not open $file";
	}

	while(<IN>){
		&$CallSub;
		chomp;
		s/^.*?"[^\s]+\s+//;
		s/\s+[^\s]+".*$//;
		next if(/gif$/i);
		next if(/png$/i);
		next if(/js$/i);
		next if(/jpg$/i);
		next if(/css$/i);
		next if(/swf$/i);
		$TH{$_}++;
	}
	close IN;
}


#为了排序，将哈希数据转存入数组
#数组结构 URL重复出现次数(TAB分隔符)IP地址
while((my $k,$v)=each %TH){
	push @Report,"$v	$k";
}

#数组排序
@Report=sort { $a<=>$b } @Report;

#输出
open OUT,">","$Output"or die "cannot open $Output: $!";
select OUT;
while (my $line=(pop @Report)){
	print "$line\n";
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

