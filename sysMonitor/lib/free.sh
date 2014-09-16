#!/bin/bash
free.exec(){
	free -m
}

free.show(){
	r=$(awk '/^Mem/{total=$3}
		/^-/{used=$3}
		/^Swap/{swap_total=$2;swap_used=$3}
		END{printf ("%.2f%%:%.2f%%",used/total*100,swap_used/swap_total*100)}'  $1)
	echo -e "Memory used: \e[31m${r%:*}\033[0m"
	echo -e "Swap used: \e[31m${r#*:}\033[0m"
}
