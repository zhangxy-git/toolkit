appBackup.sh: 运行这个脚本执行备份
createList.sh: appBackup.sh调用createList.sh 生成需要备份的文件列表
ftpPut.sh: appBackup.sh调用ftpPut.sh上传备份文件至FTP

使用方法:
1.修改ftpPut.sh中的Server及Identity(填写加密后的密文)
2.修改createList.sh， 使执行createList.sh时生成需要备份的文件列表
3.执行备份操作 
./appBackup.sh PASSWORD



ftpPut.sh中:
Server的明文格式为:
FTP服务器IP地址     端口

Identity明文格式:
用户名   密码



加解方法(PASSWORD是密码):
$ echo 'hello world' | openssl enc  -aes-256-cfb  -a -k PASSWORD
U2FsdGVkX18xWA5iuI7qNoxxAVvNmCvZZ/J90A==

$ echo 'U2FsdGVkX18xWA5iuI7qNoxxAVvNmCvZZ/J90A==' | openssl enc -aes-256-cfb  -d -a -k PASSWORD
hello world

