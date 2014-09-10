#!/bin/bash
vmstat.exec(){
	vmstat 1 2 | awk 'NR=="3"{next};1'
}

vmstat.show(){
	cat $1
}
