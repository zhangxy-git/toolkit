#!/bin/bash
function top.exec {
	top -b -n 2 | awk '/^top/{t++};t>"1"{if(/^ *[^0-9 ]|^$/){print}else{if($9*1000>30000){print}}}'
}
function top.show {
	r=$(cat $1|sed '/^ *[0-9][0-9]* /s/\(^.*$\)/\\e[31m\1\\033[0m/')	
	echo -e "$r"
}
