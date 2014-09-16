#!/bin/bash 
netstat.exec(){
	local r
	r=$(netstat -na)
	echo "$r" | awk '/^tcp/{a[$NF]++}END{n=asorti(a,b);for(i=1;i<=n;i++){print b[i],a[b[i]]}}'
	
	[[  -d "$1/netstat_detail" ]] || mkdir -p "$1/netstat_detail"

	echo "$r" >> $1/netstat_detail/netstat_detail_$(date "+%Y-%m-%d_%H%M%S").log
}

netstat.show(){
	r=$(cat $1|sed 's/\([0-9][0-9]*\)/\\e[31m\1\\033[0m/g')
	echo -e $r
}
