#!/bin/sh

PATH="/sbin:/usr/sbin:/usr/local/sbin:/bin:/usr/bin:/usr/local/bin"

RRUN=`ps ax | grep highload-report.sh | grep -v grep | wc -l`
RRUN=0$RRUN
if [ $RRUN -gt 2 ]; then
  echo "Error! Highload Report alredy running. Please check output command 'ps aux'."
  exit
fi

STAMP=`date +%d%m%Y-%H%M%S`
FLAGD=`date +%s`
REPORT=""


if [ -f /tmp/highload-report.flag ]; then
  FLAGL=`cat /tmp/highload-report.flag | head -1`
  CNTL=`cat /tmp/highload-report.flag | tail -1`
  DELTA=$((FLAGD-FLAGL))
  if [ $DELTA -gt 280 -a $CNTL -eq 1 ]; then
    echo $FLAGD > /tmp/highload-report.flag
    echo 5 >> /tmp/highload-report.flag
    REPORT="5"
    DELTA=0
  fi
  if [ $DELTA -gt 280 -a $CNTL -ne 10 ]; then
    echo $FLAGD > /tmp/highload-report.flag
    echo 10 >> /tmp/highload-report.flag
    REPORT="10"
    DELTA=0
  fi
  if [ $DELTA -gt 1180 ]; then
    echo $FLAGD > /tmp/highload-report.flag
    echo 1 >> /tmp/highload-report.flag
    REPORT="100"
  fi
else
  echo $FLAGD > /tmp/highload-report.flag
  echo 1 >> /tmp/highload-report.flag
  REPORT="1"
fi

echo "<html><body>" >> /tmp/$STAMP.tmp
echo "<h3>Load average</h3>" >> /tmp/$STAMP.tmp
echo "Command: top -b | head -45" >> /tmp/$STAMP.tmp
echo "<p><pre>" >> /tmp/$STAMP.tmp
echo >> /tmp/$STAMP.tmp
top -b | head -45 >> /tmp/$STAMP.tmp 2>&1
echo >> /tmp/$STAMP.tmp
echo "</pre></p>" >> /tmp/$STAMP.tmp

echo "<h3>Mysql processes</h3>" >> /tmp/$STAMP.tmp
echo "Command: mysql -u -p -e SHOW FULL PROCESSLIST" >> /tmp/$STAMP.tmp
echo "<p><pre>" >> /tmp/$STAMP.tmp
echo >> /tmp/$STAMP.tmp
mysql -u`cat /root/bin/hr/.mysqlu` -p`cat /root/bin/hr/.mysqlp` -e "SHOW FULL PROCESSLIST" >> /tmp/$STAMP.tmp 2>&1
echo >> /tmp/$STAMP.tmp
echo "</pre></p>" >> /tmp/$STAMP.tmp

echo "<h3>Mysql status</h3>" >> /tmp/$STAMP.tmp
echo "Command: mysql -u -p -e SHOW GLOBAL STATUS where value !=0" >> /tmp/$STAMP.tmp
echo "<p><pre>" >> /tmp/$STAMP.tmp
echo >> /tmp/$STAMP.tmp
mysql -u`cat /root/bin/hr/.mysqlu` -p`cat /root/bin/hr/.mysqlp` -e "SHOW GLOBAL STATUS where value !=0" >> /tmp/$STAMP.tmp 2>&1
echo >> /tmp/$STAMP.tmp
echo "</pre></p>" >> /tmp/$STAMP.tmp

echo "<h3>Memory process list (top 100)</h3>" >> /tmp/$STAMP.tmp
echo "Command: ps -ewwwo pid,size,command --sort -size | head -100 | awk { pid=$1 ; printf(%7s, pid) }{ hr=$2/1024 ; printf(%8.2f Mb , hr) } { for ( x=3 ; x<=NF ; x++ ) { printf(%s ,$x) } print _ }'" >> /tmp/$STAMP.tmp
echo "<p><pre>" >> /tmp/$STAMP.tmp
echo >> /tmp/$STAMP.tmp
ps -ewwwo pid,size,command --sort -size | head -100 | awk '{ pid=$1 ; printf("%7s ", pid) }{ hr=$2/1024 ; printf("%8.2f Mb ", hr) } { for ( x=3 ; x<=NF ; x++ ) { printf("%s ",$x) } print "" }' >> /tmp/$STAMP.tmp 2>&1
echo >> /tmp/$STAMP.tmp
echo "</pre></p>" >> /tmp/$STAMP.tmp

echo "<h3>Process list (sort by cpu)</h3>" >> /tmp/$STAMP.tmp
echo "Command: ps -ewwwo pcpu,pid,user,command --sort -pcpu" >> /tmp/$STAMP.tmp
echo "<p><pre>" >> /tmp/$STAMP.tmp
echo >> /tmp/$STAMP.tmp
ps -ewwwo pcpu,pid,user,command --sort -pcpu >> /tmp/$STAMP.tmp 2>&1
echo >> /tmp/$STAMP.tmp
echo "</pre></p>" >> /tmp/$STAMP.tmp

echo "<h3>Operations IO</h3>" >> /tmp/$STAMP.tmp
echo "Command: iotop -b -n 1 -P" >> /tmp/$STAMP.tmp
echo "<p><pre>" >> /tmp/$STAMP.tmp
echo >> /tmp/$STAMP.tmp
iotop -b -n 1 -P >> /tmp/$STAMP.tmp 2>&1
echo >> /tmp/$STAMP.tmp
echo "</pre></p>" >> /tmp/$STAMP.tmp

echo "<h3>IOstat</h3>" >> /tmp/$STAMP.tmp
echo "Command: iostat -xk" >> /tmp/$STAMP.tmp
echo "<p><pre>" >> /tmp/$STAMP.tmp
echo >> /tmp/$STAMP.tmp
iostat -xk >> /tmp/$STAMP.tmp 2>&1
echo >> /tmp/$STAMP.tmp
echo "</pre></p>" >> /tmp/$STAMP.tmp

echo "<h3>Php-fpm for "`cat /root/bin/hr/.address`"</h3>" >> /tmp/$STAMP.tmp
echo "Command: wget -q -O - "`cat /root/bin/hr/.address`"/status?full" >> /tmp/$STAMP.tmp
echo "<p><pre>" >> /tmp/$STAMP.tmp
echo >> /tmp/$STAMP.tmp
wget -q -O - http://`cat /root/bin/hr/.address`/status?full >> /tmp/$STAMP.tmp 2>&1
echo >> /tmp/$STAMP.tmp
echo "</pre></p>" >> /tmp/$STAMP.tmp

echo "<h3>Nginx</h3>" >> /tmp/$STAMP.tmp
echo "Command: wget -q -O - http://`cat /root/bin/hr/.address`/nginx_status" >> /tmp/$STAMP.tmp
echo "<p><pre>" >> /tmp/$STAMP.tmp
echo >> /tmp/$STAMP.tmp
wget -q -O - http://`cat /root/bin/hr/.address`/nginx_status >> /tmp/$STAMP.tmp 2>&1
echo >> /tmp/$STAMP.tmp
echo "</pre></p>" >> /tmp/$STAMP.tmp

echo "<h3>Connections report</h3>" >> /tmp/$STAMP.tmp
echo "Command: netstat -plan | grep :80 | awk {print $5} | cut -d: -f 1 | sort | uniq -c | sort -rn" >> /tmp/$STAMP.tmp
echo "<p><pre>" >> /tmp/$STAMP.tmp
echo >> /tmp/$STAMP.tmp
netstat -plan | grep :80 | awk {'print $5'} | cut -d: -f 1 | sort | uniq -c | sort -rn >> /tmp/$STAMP.tmp 2>&1
echo >> /tmp/$STAMP.tmp
echo "</pre></p>" >> /tmp/$STAMP.tmp

echo "<h3>SYN tcp/udp session</h3>" >> /tmp/$STAMP.tmp
echo "Command: netstat -n | egrep (tcp|udp) | grep SYN" >> /tmp/$STAMP.tmp
echo "<p><pre>" >> /tmp/$STAMP.tmp
echo >> /tmp/$STAMP.tmp
netstat -n | egrep '(tcp|udp)' | grep SYN >> /tmp/$STAMP.tmp 2>&1
echo >> /tmp/$STAMP.tmp
echo "</pre></p>" >> /tmp/$STAMP.tmp

SUBJECT="`hostname` HighLoad report. Loadavg (5min) more that 13"

echo "</body></html>" >> /tmp/$STAMP.tmp

if [ -n "$REPORT" ]; then
cat - /tmp/$STAMP.tmp <<EOF | sendmail -oi -t
To: d.kochetov@initlab.ru
Cc: r.agabekov@initlab.ru
Subject: $SUBJECT
Content-Type: text/html; charset=utf8
Content-Transfer-Encoding: 8bit
MIME-Version: 1.0

EOF

fi
cp /tmp/$STAMP.tmp /var/log/highload-report/$STAMP.log
rm /tmp/$STAMP.tmp
find /var/log/highload-report/ -type f -mtime +30 -delete

#if [ "$1" = "apache-start" ]; then
#    sems=$(ipcs -s | grep apache | awk --source '/0x0*.*[0-9]* .*/ {print $2}')
#    for sem in $sems
#    do
#      ipcrm sem $sem
#    done
#    /etc/init.d/httpd start
#fi

#if [ "$1" = "apache-stop" ]; then
#    killall -9 httpd
#fi

#if [ "$1" = "force-restart" ]; then
#    killall -9 httpd
#    sleep 2
#    sems=$(ipcs -s | grep apache | awk --source '/0x0*.*[0-9]* .*/ {print $2}')
#    for sem in $sems
#    do
#      ipcrm sem $sem
#    done
#    /etc/init.d/httpd start
#fi

exit 1
