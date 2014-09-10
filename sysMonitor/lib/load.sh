#!/bin/bash
load.exec(){
	awk '{print "Loadavg 1min: "$1," 5min: "$2,"  15min: "$3}' /proc/loadavg
}

load.show(){
	cat $1
}
