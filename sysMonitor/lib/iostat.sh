#!/bin/bash
iostat.exec(){
	iostat -kdx 3  2 | awk '/^Device/{i++};i=="2"{print}'
}

iostat.show(){
	awk '/^dm/{exit};1' $1
}
