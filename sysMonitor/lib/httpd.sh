#!/bin/bash

httpd.exec(){
	echo "HTTPD:$(ps -ef | grep [h]ttpd|wc -l)"
}

httpd.show(){
	r=$(cat $1|sed 's/\([0-9][0-9]*\)/\\e[31m\1\\033[0m/g')
	echo -e  $r

}
