#!/bin/bash

httpd.exec(){
	echo "HTTPD:$(ps -ef | grep [h]ttpd|wc -l)"
}

httpd.show(){
	cat $1

}
