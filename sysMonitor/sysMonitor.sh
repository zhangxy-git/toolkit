#!/bin/bash

#脚本家目录，此处设为null则在Begin方法内自动获取
home=
#临时文件夹，默认使用tempfs，如果设为空，则在Begin方法内根据temp_dir_template自动重设,下同
temp_dir=/dev/shm/$(basename $0)_$(date "+%Y%m%d%H%M%S")
log_dir=
lib_dir=
#路径模版
temp_dir_template='$home/tmp'
log_dir_template='$home/log'
lib_dir_template='$home/lib'
#采样时间间隔
delay=5
main_pid=$$
declare -a class


Main(){
	#创建临时文件夹
	if [[ ! -d $temp_dir ]] ;then 
		mkdir -p $temp_dir
		if [[ $? != "0" ]] ;then
			echo "create temp dir failed!"
			exit 1
		fi
	fi
	#监控命令控制方法，后台执行。
	MonitorCtl &
	#解决首次执行时数据文件尚未生成,ShowCtl报错问题
	printf "Preparing(about $((delay-$(date "+%s")%delay+5))s) ."
	while : ;do
		local m=0
		for ((i=0;i<${#class[@]};i++)) ;do
			[[ -f "$temp_dir/${class[$i]}.log" ]] || m=1
		done
		[[ $m == "0" ]] && break
		printf "."
		sleep 1
		
		
	done 
	#显示实时状态，阻塞主程序，防止MonitorCtl意外退出
	ShowCtl
}

#初始化
Begin(){
        set -e
	#捕获crtl+c等信号，执行执行清理函数：End
        trap 'End'  TERM INT  EXIT
	#获取脚本所在文件夹 ${0:0:1} 是$0的第一个字符，如果为'/'，说明使用绝对路径调用，否则是使用相对路径调用
	if [[ -z "$home" ]] ;then
        	if [[ ${0:0:1} == '/' ]] ;then
               		home=$(dirname $0)
        	else
                	home=$PWD/$(dirname $0)
        	fi
	fi
	
	#将$home代入模版，重设路径变量
        [[ -z "$temp_dir" ]] && eval temp_dir=$temp_dir_template
        [[ -z "$log_dir"  ]] && eval log_dir=$log_dir_template
        [[ -z "$lib_dir"  ]] && eval lib_dir=$lib_dir_template
        [[ -d "$log_dir" ]] || mkdir -p "$log_dir"
	local f
	#取得lib下所有"类"
	#例:func.sh 其中包含func.exec 与func.show两个方法 
	#func.exec : 执行某个监控命令，将结果输出到STDOUT
	#func.show : 解析func.exec的输出(已经保存到文件，文件名通过参数$1传递给方法)，格式化后输出到STDOUT，用于查看实时状态
        for f in $lib_dir/*sh ;do
                class[${#class[@]}]=$(basename $f .sh)
        done 
	#载入所有方法
	for ((i=0;i<${#class[@]};i++)) ;do
		source $lib_dir/${class[$i]}.sh
	done
	#判断当前系统语言编码
	if $(echo $LANG | egrep -iq '(utf8|utf-8)') ;then
		Encoding=utf-8
	else
		Encoding=gb18030
	fi
}

#监控方法控制
MonitorCtl(){
	while : ;do
		#计算出距离下一个执行时间点还有n秒，并sleep n
		sleep  $((delay-$(date "+%s")%delay))
		local run_time=$(date +"%Y%m%d %H:%M:%S")
		local i 
		#遍历所有监控类，传递给Execute方法,后台并行执行
        	for ((i=0;i<${#class[@]};i++)) ;do
                	Execute ${class[$i]}  &
        	done
		#如果监控到主程序退出，则MonitorCtl亦自动退出
		#主程序退出时会杀掉所有子进程，此处仅作为一个防止意外的手段
		[[ -d /proc/$main_pid ]] || exit  
		
	done
}

#显示实时信息
ShowCtl(){
	while : ;do
		clear
		date 
		local i  col
		col=$( stty  -a |awk '/^speed/{sub("[^0-9]","",$7);print $7}')
		#直接执行*.show方法
		for ((i=0;i<${#class[@]};i++)) ;do
		#	printf  "${class[$i]}\n"
	#		col=$((col-${#class[$i]}))
			line=$(perl -e "print ' ' x $((col-${#class[$i]}-2))")
			echo -e "\033[7m${class[$i]}${line}\033[0m"
			${class[$i]}.show  "$temp_dir/${class[$i]}.log"  ${class[$i]}
			echo
		done
		echo
		echo
		MsgOut "5oyJQ1RSTCtD6YCA5Ye677yM5bm256Gu6K6k5ZCO5Y+w6L+b56iL5piv5ZCm5YWo6YOo6YCA5Ye6
Cg=="
		sleep 5
	done

}

#执行监控方法，生成日志
Execute(){
	local func=${1}.exec
	#锁文件，每个方法只能启动一个实例
	local lock=$temp_dir/${func}.lock
	if [[ -f $lock ]] ; then
		echo lock $func 
		 return
	fi
	touch $lock
	#执行监控方法，为满足记录额外信息的需求，传递$log_dir参数，
	result=$($func "$log_dir" 2>&1)
	echo -e  "$result" >$temp_dir/${1}.log
	echo -e "TIME:$run_time\n$result" >>$log_dir/${1}.log
	rm $lock
 
}

#杀掉所有子进程
KillChild(){
        local child_pid=`FindChild $$`
        [[ -n "$child_pid" ]] && kill -9  $child_pid 2>/dev/null
}

#递归查找各种子子孙孙进程...
FindChild(){
	local i
        for i in $(pgrep -P $1)  ;do
                echo $i 
                FindChild $i
        done
}

#退出前清理
End(){
	rm -rf $temp_dir
	KillChild
	MsgOut "5q2j5Zyo6YCA5Ye6Li4K"

}
MsgOut(){
	echo "$1" |openssl base64 -d | iconv -f utf-8 -t $Encoding
}

Begin
Main

