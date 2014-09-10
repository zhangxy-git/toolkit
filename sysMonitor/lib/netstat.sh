#!/bin/bash 
netstat.exec(){
	local r
	r=$(netstat -na)
	echo "$r" | awk '/^tcp/{a[$NF]++}END{n=asorti(a,b);for(i=1;i<=n;i++){print b[i],a[b[i]]}}'
	
	[[  -d "$1/netstat_detail" ]] || mkdir -p "$1/netstat_detail"

	echo "$r" >> $1/netstat_detail/netstat_detail_$(date "+%Y-%m-%d_%H%M%S").log
}

netstat.show(){
	cat $1
}
