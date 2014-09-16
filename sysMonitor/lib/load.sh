#!/bin/bash
load.exec(){
	awk '{print "Loadavg 1min: "$1," 5min: "$2,"  15min: "$3}' /proc/loadavg
}

load.show(){
	r=$(cat $1|sed 's/\([0-9][0-9]*\)/\\e[31m\1\\033[0m/g')
	echo -e $r
}
