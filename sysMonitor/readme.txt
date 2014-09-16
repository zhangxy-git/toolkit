1.执行sysMonitor.sh开始监控，使用ctrl+c退出，退出后应检查下是否有遗留进程。

2.使用parseLog.py生成报表。

parseLog.py中，template是输出格式模板

对于只有一行输出数据的指标，直接采用命令输出的列头去掉特殊字符后作为指标名称，比如vmstat:
CPU空闲率在模板中表示为 $id 

 r  b   swpd   free   buff  cache   si   so    bi    bo   in   cs us sy id wa st
 0  0      0 370396 164048 378196    0    0     0     0 1003   40  0  0 100  0  0



对于有多行输出内容的命令，使用(行头_列头)的格式，去掉特殊字符后作为指标名称，比如sar：
eth0的rxbyt/s表示为eth0_rxbyts

09:10:40 AM     IFACE   rxpck/s   txpck/s   rxbyt/s   txbyt/s   rxcmp/s   txcmp/s  rxmcst/s
09:10:43 AM        lo      0.00      0.00      0.00      0.00      0.00      0.00      0.00
09:10:43 AM      eth0      0.66      0.33     86.09     21.85      0.00      0.00      0.00