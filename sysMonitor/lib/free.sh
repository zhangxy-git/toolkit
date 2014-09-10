#!/bin/bash
free.exec(){
	free -m
}

free.show(){
	awk '/^Mem/{total=$3}
		/^-/{used=$3}
		/^Swap/{swap_total=$2;swap_used=$3}
		END{printf ("Memory used: %.2f%%\nSwap used: %.2f%%\n",used/total*100,swap_used/swap_total*100)}'  $1
}
