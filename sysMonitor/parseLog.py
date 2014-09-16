#!/usr/bin/python
import glob
import sys
import re
from string import Template
LOG_DIR = "log"
OUTPUT_FILE = "result.csv"
template = '$load,$id,$mem_pct,$ESTABLISHED,$TIME_WAIT,$CLOSE_WAIT,$FIN_WAIT,$vda_util,$vda_avgqusz,$vda_svctm,$eth0_txpcks,$eth0_txpcks,$eth0_rxbyts,$eth0_txbyts,$processed,$idle'


class ParseLog:
	result = {}
	item_label = {}
	time_label = {}
	def update(self,file,type):
		if not hasattr(ConvertData,type):
			print "skip %s %s!" %(type,file)
		conver = ConvertData()
		data = []
		IN = open(file,"r")
		for line in IN :
			line = line.rstrip("\n\r")
			if line.startswith("TIME:") :
				if len(data):
					r = eval ("conver.%s(%s)" % (type,data))
					for i in r.keys():
						ParseLog.item_label.update({i:""})
					d = ParseLog.result.get(time,{})
					d.update(r)
					ParseLog.result.update({time:d})
					data = []
				time = re.sub("^TIME:","",line)
				ParseLog.time_label.update({time:""})
				continue
			data.append(line)
		IN.close
	def get(self,time):
		r = {}
		for i in ParseLog.item_label.keys():
			if ParseLog.result.get(time) and ParseLog.result.get(time).get(i):
				r.update({i:ParseLog.result.get(time).get(i)})
			else:
				r.update({i:"N/A"})
		return r
	

class ConvertData:
	def free(self,data) :
		for line in data:
			col = line.split()
			if line.startswith("Mem"):
				mem_total = float(col[1])
			elif line.startswith("-/+ "):
				mem_used = float(col[2])
			elif line.startswith("Swap"):
				swap_total = float(col[1])
				swap_used = float(col[2])
		mem_pct =  mem_used / mem_total * 100
		swap_pct =  swap_used / swap_total * 100
		return {"mem_pct":"%.2f%%" % mem_pct,"swap_pct": "%.2f%%" % swap_pct}

	def load(self,data):
		return {"load":data[0].split()[2]}
	
	def httpd(self,data):
		return {"httpd":data[0].split(":")[1]}

	def netstat(self,data):
		r = {}
		for line in data:
			r.update({line.split()[0]:line.split()[1]})
		return r
	
	def iostat(self,data):
		r = {}
		for line in data:
			line = re.sub("[^_a-zA-Z0-9 ]","",line)
			if line.startswith("Device"):
				k = line.split()
			else:
				i = 0
				l = line.split()
				for v in l:
					r.update({l[0] + "_" + k[i]:v})
					i = i + 1
		return r
	def sar_net(self,data):
		r = {}
		k = []
		cut = 0
                for line in data:
			line = re.sub("[^_a-zA-Z0-9 \t]","",line)
			if not re.search("^[0-9]",line):
				continue
			l = line.split()
			if re.search("IFACE",line):
				while True:
					if l[0] == 'IFACE':
						k = l
						break
					else:
						del l[0]
						cut = cut + 1

			else:
				for i in range(cut):
					del l[0]
				i=0
				for v in l:
					r.update({l[0] + "_" + k[i]:v})
					i = i + 1
		return r
	def vmstat(self,data):
		r = {}
		for line in data:
			line = re.sub("[^_a-zA-Z0-9 ]","",line)
			if line.startswith("procs"):
				continue
			if re.search("r",line):
				k = line.split()
			else:
				i = 0
				for v in line.split():
					r.update({k[i]:v})
					i = i + 1
		return r
	def httpd_status(delf,data):
		r = {}
		r.update({data[0].split(":")[0]:data[0].split(":")[1]})
		r.update({data[1].split(":")[0]:data[1].split(":")[1]})
		return r
def formatting():
	p = ParseLog()
	logfile = glob.glob(LOG_DIR + "/*.log")
	for file in logfile :
		type = re.findall("/([^/.]*).log$",file)
		if not hasattr(ConvertData,type[0]):
			continue
		p.update(file,type[0])
	
	
	OUT = open(OUTPUT_FILE,"w")
	output_template = Template(template)
	OUT.write("time," + template + "\n")
	for i in sorted(ParseLog.time_label):
		OUT.write(i + "," + re.sub("\$[^,]*","N/A",output_template.safe_substitute(p.get(i))) + "\n")
	OUT.close()

if __name__ == '__main__':
	formatting()
