#!/usr/bin/perl
use warnings;
use strict;
use File::Copy;
our ($date_time,%size);
my $work_dir = '/storage/project/AccessControl';
my $log = "$work_dir/logs/AccessControl.log";
my $out_dir = "$work_dir/queue";
my $temp_dir = "$work_dir/temp";
my $ban_dir = "$work_dir/ban";
my $ssh_auth_log = '/var/log/auth.log';
my $dav_auth_log = '/var/log/apache2/dav_errorlog.log';
#执行时间间隔
my $interval = '60';
#阈值
my $threshold = '5';
#屏蔽时间
my $block_time = '300';

#$size{$dav_auth_log} = (stat "$dav_auth_log")[7] or die $! ;
$size{$ssh_auth_log} = (stat "$ssh_auth_log")[7] or die $! ;



while (1){
	sleep $interval;
	open LOG,">>","$log" or die $!;
	select LOG; $| = 1;
	*STDERR = *LOG;
	chdir $work_dir or die $!;
	my $batch_time = localtime;
	print "\nMission Started At $batch_time.\n";
	&sshLogAnalysis;
#	&davLogAnalysis;
	&banCtl;
	print "Mission Completed.\n";
	close LOG;
	close STDERR;
}

#分析ssh登录日志
sub sshLogAnalysis{
	my ($s,$pid,$result,%data,%ip );
	&setDate;
	print "Task SLMS$date_time Insertion Sequence.\n";
	
	#根据文件大小判断文件是否更新.
	$s = (stat "$ssh_auth_log")[7] or die $!;
	if ( $s == $size{$ssh_auth_log} ){
		print "SSH Authentication Log Size: $size{$ssh_auth_log}.\n";
		print "Sequence SLMS$date_time Completed.\n";
		return;
	}
	#移动指针至上次处理完毕的位置
	$size{$ssh_auth_log} = '0' if ( $s < $size{$ssh_auth_log});
	open IN,"$ssh_auth_log" or die $!;
	seek (IN,$size{$ssh_auth_log},"0") or die $!;
	$size{$ssh_auth_log} = $s;
	
	#按照ssh日志中记录的进程PID,将日志按照会话分割
	while (<IN>){
		next if ! / sshd\[([0-9]+)\]: /;
		$pid = $1 ;
		$data{$pid} .= $_ ;
	}
	close IN;
	
	#分析每个会话是否认证成功,将认证失败的源地址加入哈希数组
	for (keys %data){
		next if $data{$_} =~ m/Authname.*session opened for user/s ;
		$ip{$1} += 1 if ( $data{$_} =~ m/Authname;Remote:[\s]+([0-9.]+)-/s );
	}

	#统计哈希数组中IP地址出现的次数,提取超过阈值的IP(跳过内网地址,下同)
	for (keys %ip){
		next if ( $ip{$_} < $threshold );
		next if ( $_ =~ m/^(10\.|172\.16|192\.168)/ );
		$result .= "$_\n";
		print "Found IP Address: $_\n";
	}

	#将失败次数超过阈值的IP写入文件,投递至封禁队列
	if($result){
		print "Create Batch File: ";
		my $out_file = "S${date_time}_SLMS.TXT";
		print "$out_file";
		open OUT,">","$temp_dir/$out_file" or die $!;
		print OUT "#SLMS: S${date_time}\n";
		print OUT "$result" or die $!;
		close OUT;
		print " Successful.\nPut $out_file Into Queue " ;
		move("$temp_dir/$out_file","$out_dir/$out_file") or die $!;
		print "Successful.\n";
	}
	print "Sequence SLMS$date_time Completed.\n";
}


#分析apache webdav日志
sub davLogAnalysis{
	my (%ip,$result,$s);
	&setDate;
	print "Task DLMS$date_time Insertion Sequence.\n";
	
	#根据文件大小判断文件是否更新
	$s = (stat "$dav_auth_log")[7] or die $!;
	if ( $s == $size{$dav_auth_log} ){
		print "DAV Authentication Log Size: $size{$dav_auth_log}.\n";
		print "Sequence DLMS$date_time Completed.\n";
		return;
	}

	#移动指针至上次处理完毕的位置
	$size{$dav_auth_log} = '0' if ( $s < $size{$dav_auth_log});
	open IN,"$dav_auth_log" or die $!;
	seek (IN,$size{$dav_auth_log},"0") or die $!;
	$size{$dav_auth_log} = $s;
	#提取日志中登录失败的IP地址
	while (<IN>){
		next if ! /auth_.*error/;
		/auth_.*error.*\[client ([0-9.]+):[0-9]+\]/;
		$ip{$1} += 1;
	}
	close IN;
	
	#提取失败次数超过阈值的IP地址
	for (keys %ip){
		next if ( $ip{$_} < $threshold );
		next if ( $_ =~ /^(10\.|172\.16|192\.168)/ );
		$result .= "$_\n";
		print "Found IP Address: $_\n";
	}
	
	#将失败次数超过阈值的IP写入文件,投递至封禁队列
	if($result){
		print "Create Batch File: ";
		my $out_file = "S${date_time}_DLMS.TXT";
		print "$out_file";
		open OUT,">","$temp_dir/$out_file" or die $!;
		print OUT "#DLMS: S${date_time}\n";
		print OUT "$result" or die $!;
		close OUT;
		print " Successful.\nPut $out_file Into Queue " ;
		move("$temp_dir/$out_file","$out_dir/$out_file") or die $!;
		print "Successful.\n";
	}
	print "Sequence DLMS$date_time Completed.\n";
}

#封禁控制函数
sub banCtl{
	my (%block_list,%deblock_list );
	my @batch_file = glob("$out_dir/*");
	my @block_his = glob("$ban_dir/*");
	my $oper_time = time;
	my $deblock_time = $oper_time + $block_time;

	#从队列文件夹统计待封禁IP
	for (@batch_file){
		chomp;
		open IN,"$_" or die $!;
		my $f = $_;
		while (<IN>){
			chomp;
			next if (/^#/);
			$block_list{$_} = $_;
		}
		close IN;
		unlink "$f" or die $!;
	}

	#从状态文件夹统计待解封IP
	for(@block_his){
		open IN,"$_" or die $!;
		chomp (my ($k,$v) = split (/\|/,<IN>) );
		if($v < $oper_time){
			$deblock_list{$k} = $_ ;
		}
		close IN;

	}
	
	#如待解封地址未在待封禁列表,解封IP
	for (keys %deblock_list){
		if($block_list{$_}){
			print "IP Address $_ In Ban List,skip.\n";
			next;
		}
		print "Deblock $_ ";
		my $cmd = "/sbin/iptables -D INPUT   -s $_ -j DROP";
		my $cmd_log = `$cmd 2>&1`;
		if ($? == "0"){
			unlink $deblock_list{$_} or die $!;
			print "Successful.\n";
		}else{
			print "Failed.\n";
			print "ERROR:$cmd_log";
		}


	}

	#调用iptables屏蔽待封IP,并写入状态文件夹
	for (keys %block_list){
		print "Block $_ ";
		my $cmd = "/sbin/iptables -I INPUT  -s $_ -j DROP" ;
		my $cmd_log = `$cmd 2>&1`;
		if ($? == "0"){
			open BAN,">","$ban_dir/${_}.txt" or die $!;
			print BAN "$_|$deblock_time";
			close BAN;
			print "Successful.\n";
		}else{
			print "Failed.\n";
			print "ERROR:$cmd_log";
		}
	}
}

#获取当前时间
sub setDate {
	my @t = localtime;
	$t[5] +=1900;
	$t[4] += 1;
	$date_time = sprintf ("%04d%02d%02d%02d%02d%02d",$t[5],$t[4],$t[3],$t[2],$t[1],$t[0]) ;

}
