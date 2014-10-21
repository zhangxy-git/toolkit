#!/usr/bin/python
import pickle
import time
import os
import re
import glob

RECORD = 'last.db'
LOG_DIR = './'
ALARM = 200
OUT = 'monitor.log'


class GetLine:
    def __init__(self,filelist,record):
        self.list = filelist
        self.end = {}
        self.record = record
        try:
            s = open(self.record,'r')
            self.start = pickle.load(s)
            s.close()
        except:
            self.start = {}
        for f in self.list:
            size = os.stat(f).st_size
            self.end.update({f:size})

    def __del__(self):
        s = open (self.record,'wb')
        pickle.dump(self.end,s)
        s.close()

    def open(self,filename):
        self.fd = open(filename,'r')
        self.fd.seek(int(self.start.setdefault(filename,0)))

    def close(self,filename):
        self.fd.close()

    def getline(self):
        if self.fd.tell() < self.end:
            return self.fd.readline()
        else:
            return

class AnalyzeLog:
    def __init__(self,alarm,time):
        self.data = {}
        self.result = []
        self.time = time
        self.alarm = alarm
        self.regex = re.compile(r'^([0-9.]*) .*?/[0-9]{4}:([0-9:]*) .*?"[^ ]* (/[^ ?]*)')

    def load(self,line):
        match = self.regex.match(line)
        if match and not re.search('(css|js|png|gif|swf|jpg|jpeg)$',match.group(3)) :
            self.data.setdefault(match.group(1),{}).update({match.group(3):self.data.setdefault(match.group(1),{}).setdefault(match.group(3),0) + 1})

    def dump(self):
        return self.result

    def commit(self,filename):
        for i in self.data.keys():
            for j in self.data.get(i).keys():
                if self.data.get(i).get(j) > self.alarm:
                    self.result.append({'BatchTime':self.time,'IpAddr':i,'Location':j,'Count':self.data.get(i).get(j),'FileName':filename})
        self.data = {}




def main():
    today = str(time.strftime('%y%m%d',time.localtime(time.time() - 60)))
    batchtime = time.strftime('%Y-%m-%d %H:%M:%S')

    filelist = glob.glob(LOG_DIR + '/*accesslog*' + today + '*')
    r = AnalyzeLog(ALARM,batchtime)
    l = GetLine(filelist,RECORD)

    for f in  filelist:
        l.open(f)
        line = l.getline()
        while line :
            r.load(line)
            line = l.getline()
        l.close(f)
        r.commit(f)
    del l

    fd = open(OUT,'a')
    for i in r.dump():
        fd.write(str(i) + '\n')
#    if len(r.dump()):
#        fd.write(str(r.dump()) + '\n')
    fd.close()
if __name__ == '__main__':
    main()

