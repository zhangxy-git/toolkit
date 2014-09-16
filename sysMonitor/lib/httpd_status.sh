#!/bin/bash
httpd_status.exec(){
	curl --connect-timeout 1 http://127.0.0.1/server-status 2>/dev/null | sed -n '/requests/s/^[^0-9]*\([0-9]*\) requests.* \([0-9]*\) idle.*$/processed:\1\nidle:\2/p'
}

httpd_status.show(){
	r=$(cat $1|sed 's/\([0-9][0-9]*\)/\\e[31m\1\\033[0m/g')
	echo -e $r
}
