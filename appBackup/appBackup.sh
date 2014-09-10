#!/bin/bash
Home=
Log='$Home/appBackup.log'
TempDir='$Home/tmp'
TempFile='$TempDir/$(hostname)_appbackup_$(date "+%Y%m%d").tgz'
PID='$TempDir/appBackup.pid'
FileList='$TempDir/backuplist.txt'
PassKey=$1
Begin(){
	# 脚本需要密码参数,无参数则输出提示信息
	#Info是base64编码的utf-8文本
	#此处为实验性功能: 根据当前系统字符集调整输出字符集
	Info='55So5rOV77yaIGFwcEJhY2t1cC5zaCDlr4bnoIEK' 
	if [[ -z "$PassKey" ]] ;then
		echo $LANG | egrep -iq '(utf8|utf-8)'
		if [[ $? -eq "0" ]] ;then
			Encoding=utf-8
		else
			Encoding=gb18030

		fi
		echo "$Info" |openssl base64 -d | iconv -f utf-8 -t $Encoding
		exit 1
	fi
	
	#判断脚本所在路径，$0第一个字符为'/'，说明使用绝对路径调用脚本，否则为相对路径
	if [[ ${0:0:1} == '/' ]] ;then
		Home=$(dirname $0)
	else
		Home=$PWD/$(dirname $0)
	fi
	
	#重设路径
	eval TempDir=$TempDir
	eval TempFile=$TempFile
	eval PID=$PID
	eval FileList=$FileList
	eval Log=$Log

	#防止同时运行多个实例
	if [[ -f "$PID" ]] ;then
		ps -ef | grep -q "`cat $PID`[ ].*$0"
		if [[ "$?" -eq "0" ]] ;then
			Check 0
		else
			rm -f $PID
		fi
	fi
	echo $$ > $PID
}

End(){
	[[ -f "$TempFile" ]] && rm -f $TempFile
	[[ -f "$FileList" ]] && rm -f $FileList
	[[ -f "$PID" ]] && rm -f $PID

}

Main(){
	date >>$Log
	[[ -d "$TempDir" ]] || mkdir -p $TempDir
	cd $Home
	Check 1
	./createList.sh $FileList
	Check 2
	sleep 1
	tar czf $TempFile -T $FileList
	tar tf $TempFile >/dev/null
	Check 3
	./ftpPut.sh $PassKey $TempFile $(basename $TempFile)
	Check 4
}


Check(){
	if [[ $? -ne "0" ]] ;then
		echo "STEP $* Failed."  >>$Log
		exit 1 
	fi
}

Begin 
Main  >>$Log 2>&1
End
