#!/bin/bash
sar_net.exec(){
	sar -n DEV 3 1 | awk '/^Average/{exit};1'
}

sar_net.show(){
	awk '/IFACE|eth0/' $1
}
