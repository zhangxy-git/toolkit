#!/usr/bin/python
import time
import datetime
import commands
import os
import re
import sys
import glob

CONFIG_NAME='/home/ap/sfmon/monitor/conf.cfg'
SEEK_CFG='/home/ap/sfmon/monitor/seek.cfg'

def get_filename():
                hostname=commands.getoutput('hostname')
                now=time.strftime("%Y%m%d%H%M",time.localtime())
                #now=time.strftime("%H%M",time.localtime())
               #file_name="/tmp/some/logs/TRAN_"+hostname+'_'+now+'.txt'
                file_name="/home/ap/appmon/data/TRAN_"+hostname+'_'+now+'.txt'
		return file_name
def open_to_write(line,w,f,read_file,urls):
	regex = re.compile(r'^([0-9.]*) .*?/[0-9]{4}:([0-9:]*) .*?"[^ ]* (/[^ ]*) .*?" ([0-9]{3}) [0-9].*? ([0-9].*?) ')
	end_size = os.stat(read_file).st_size
	while line:
		match = regex.match(line)
		if match and match.group(3) in urls.keys(): 
			'''w.write ('ip<'+match.group(1)+'>'+'st<'+match.group(2)+'>'+'url<'+match.group(3)+'>'+'tc<>'+'ec<'+match.group(4)+'> '+'cos<'+match.group(5)+'>'+'\n')'''
			#cos = str(int (match.group(5))/1000 + 1 )
	                if urls[match.group(3)] == "URL000019" :
	                        cos = str(int (match.group(5))/10000 + 1 )
	                else :

	                        cos = str(int (match.group(5))/1000 + 1 )
			if int(match.group(4)) < 400 and int(match.group(4)) >=200 :
				ec = "000000000000"
			else :
				ec = match.group(4)
			w.write ('ip<'+match.group(1)+'> '+'st<'+match.group(2)+'> '+'url<'+match.group(3)+'> '+'tc<'+urls[match.group(3)]+'> '+'ec<'+ec+'> '+'cos<'+cos+'>'+'\n')
			if f.tell() >= end_size :
				break
		line = f.readline()
def monitor(log_name,num,seek):
	cfg=open(CONFIG_NAME,'r')
	urls={}
	read_file=log_name
	f=open(read_file,'r')
	write_file=get_filename()
	w=open(write_file,'a')
	x=int(num)
	try:
		line=cfg.readline().strip()
		list=line.split()
		while line:
			l=re.sub(r'^http://[^/]*','',list[1])
			urls.update({l:list[0]})
			line=cfg.readline().strip()
			list=line.split()
		'''while line:
				urls.append(line)
				line=cfg.readline().strip()'''
		end_size = os.stat(read_file).st_size
		if x > end_size :
			return 
		f.seek(int(x))
		line=f.readline()
		open_to_write(line,w,f,read_file,urls)		
	finally:
		a=f.tell()
		seek.update({log_name:a})
		cfg.close()
		w.close()
		f.close()

seek={}
s=open(SEEK_CFG,'r')
line=s.readline().strip().split()
while line:
	seek.update({line[0]:line[1]})
	line=s.readline().strip().split()
s.close()

d1=datetime.datetime.now()
d2=d1-datetime.timedelta(seconds=60)
d3=d2-datetime.timedelta(days=1)
i=d2.strftime('%y%m%d')
j=d3.strftime('%y%m%d')

for log in seek.keys():
	if re.match(j,log):
		del seek[log]

files=glob.glob('/opt/logs/'+'*accesslog.' + i +'*')
#files=['accesslog.14050712']
for file in files:
	if file in seek.keys():
		monitor(file,seek[file],seek)
	else:
		seek.update({file:0})
		monitor(file,seek[file],seek)
s=open(SEEK_CFG,'w')
for key in seek.keys():
	s.write(key+' '+str(seek[key])+'\n')
s.close()


