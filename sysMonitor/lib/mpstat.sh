#!/bin/bash
mpstat.exec(){
	mpstat 3 1  | awk '/^Average/{exit};1'
}

mpstat.show(){
	cat $1
}
