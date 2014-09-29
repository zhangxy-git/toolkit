#!/usr/bin/python
import cPickle as p
import time
import os
import re
import sys
import glob

SEEK_CFG = 'seek.db'
LOG_DIR = './'
ip_count = {}
result = {}
ALARM = 10
OUT = 'monitor.log'

class GetLine:
	def __init__(self,filename,start,end):
		self.filename = filename
		self.end = end
		self.input = open(self.filename,"r")
		self.input.seek(int(start))

	def __del__(self):
		self.input.close()

	def line(self):
		if self.input.tell() < self.end:
			return self.input.readline()
		else:
			return

class AnalyzeLog:
	def __init__(self):
		self.data = {}
		self.regex = re.compile(r'^([0-9.]*) .*?/[0-9]{4}:([0-9:]*) .*?"[^ ]* (/[^ ?]*)')
	def load(self,line):
		match = self.regex.match(line)
		if match and not re.search("(css|js|png|gif|swf|jpg|jpeg)$",match.group(3)) :
			k = match.group(1) + "|" + match.group(3) 
			self.data.update({k:self.data.setdefault(k,0) + 1}) 

	def dump(self):
		return self.data



	   


def main():
	batch_today = str(time.strftime('%y%m%d',time.localtime(time.time() - 60)))
	batch_yesterday= str(time.strftime('%y%m%d',time.localtime(time.time() - 86400 - 60)))
	alarm_time = time.strftime('%Y-%m-%d %H:%M:%S')
	s = open(SEEK_CFG,'r')
	try:
		seek = p.load(s)								      
	except:
		seek ={}									      
	s.close()										     
	for i in seek.keys():
		if not re.search(batch_today + "|" + batch_yesterday,i):
			del seek[i]
	r = AnalyzeLog()
	file_list = glob.glob(LOG_DIR + '/*accesslog.' + batch_today +'*')
	for f in  file_list:
		end_size = os.stat(f).st_size
		l = GetLine(f,seek.setdefault(f,0),end_size)
		seek.update({f:end_size})
		line = l.line()
		while line :
			r.load(line)
			line = l.line()
		del l
	data = r.dump()
	del r
	for k in data.keys():
		if data.get(k) > ALARM:
			print ( str(data.get(k)) + "|" + k)
	s = open ("seek.db","w")
	p.dump(seek,s)

if __name__ == "__main__":
	main()
