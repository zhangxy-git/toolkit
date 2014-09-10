#!/bin/bash
set -e
Server="U2FsdGVkX18K3/h+y0SfGRzaRS7GnTpm6z/H3GaIsIDy26w="
Identity="U2FsdGVkX1+m5nPVOvLSoKvgwiCTJPcx3dHICR+5"
key=$1
LocalFile=$2
RemoteFile=$3
Server=$(echo $Server|openssl enc -aes-256-cfb  -d -a -k $key) 
Identity=$(echo $Identity|openssl enc -aes-256-cfb  -d -a -k $key) 

{
ftp -v -n $Server <<!
user $Identity
cd 12M
bin
put  $LocalFile $RemoteFile
bye
!
}|awk 'BEGIN{i=1}/^226/{i=0};1;END{exit i}'
#ftp命令输出内容包含^226,认为ftp成功，否则认为失败。
