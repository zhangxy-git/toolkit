#!/bin/bash
#用任意方式生成需要备份的文件列表，列表文件为$1
Main(){
find /home/ccb/bea  -type f   -regextype egrep ! -regex ".*/(log|logs|tmp)/.*"
echo /home/ccb/CCSD
cat <<!
/opt/ccb
/home/ccb/shbin
!

}

Main >$1
