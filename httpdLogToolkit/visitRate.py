#!/usr/bin/python
import time
import datetime
import commands
import os
import re
import sys
import glob

CONFIG_NAME='conf.cfg'
SEEK_CFG='seek.db'
ip_count={}
result={}
alarm_baseline=10
write_file='monitor.log'

def open_to_write(line,f,read_file):
        regex = re.compile(r'^([0-9.]*) .*?/[0-9]{4}:([0-9:]*) .*?"[^ ]* (/[^ ?]*)')
        end_size = os.stat(read_file).st_size
        while line:
                match = regex.match(line)
                if match  and not re.search("(css|js|png|gif|swf|jpg|jpeg)$",match.group(3)) :
                        k = match.group(1) + "|" + match.group(3)
                        ip_count.update({k:ip_count.setdefault(k,0) + 1})
                        if f.tell() >= end_size :
                             break
                line = f.readline()
def monitor(log_name,num,seek):
        read_file=log_name
        f=open(read_file,'r')
        x=int(num)
        try:
                end_size = os.stat(read_file).st_size
                if x > end_size :
                        return 
                f.seek(int(x))
                line=f.readline()
                open_to_write(line,f,read_file)
        finally:
                a=f.tell()
                seek.update({log_name:a})
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
alarm_time=d1.strftime('%Y-%m-%d %H:%M:%S')

for log in seek.keys():
        if re.search(str(j),log):
                print log
                del seek[log]

files=glob.glob('/opt/logs/'+'*accesslog.' + i +'*')
#files=['accesslog.14050712']
for file in files:
        if file in seek.keys():
                monitor(file,seek[file],seek)
        else:
                seek.update({file:0})
                monitor(file,seek[file],seek)

w=open(write_file,'w')
# w.write(str(d1) + "\n")
for key in  ip_count.keys():
        if ip_count.get(key) > alarm_baseline :
                w.write ( str(ip_count.get(key)) + "|" + key + "\n")
w.close()
s=open(SEEK_CFG,'w')
for key in seek.keys():
        s.write(key+' '+str(seek[key])+'\n')
s.close()
