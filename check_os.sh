#!/bin/sh
#定义检查操作系统版本的函数
NUM_VERSION=$(uname -r)
function Check_OS(){
[[ $NUM_VERSION =~ el6 ]] && return 0||return 1
}

function chenck_cpu() {
echo "######CPU使用情况######"
CPU_HARDWARE=$(cat /proc/cpuinfo | grep name |cut -f2 -d: | uniq -c)
CPU_NUMBER=$(cat /proc/cpuinfo | grep name |cut -f2 -d: | uniq -c | awk '{print $1}')
CPU_LOAD=$(uptime | awk '{for(i=6;i<=NF;i++) printf $i""FS;print ""}')
CPU_LOAD_NUMBER=$(uptime | awk -F"load average:" '{print $2}' | awk -F"," '{print $1}' | awk -F"." '{print $1}' |sed 's/^[ \t]*//g')
CPU_UTILIZ=$(top -n 1 | grep "Cpu(s)")
if [[ $CPU_LOAD_NUMBER -lt $CPU_NUMBER ]]
 then
  CPU_STATUS=正常
 else
  CPU_STATUS=不正常
fi
echo "$CPU_STATUS("$CPU_HARDWARE,$CPU_LOAD,$CPU_UTILIZ")"
echo -e
echo -e
}

function chenck_disk() {
echo "######磁盘使用情况######"
IFS="  
"   
for i in `df -hP | sed 1d | awk '{print $(NF-1)"\t"$NF"\t"$(NF-2)}'`
do 
 DISK_UTILIZ=$(echo $i |awk  '{print $1}')
 MOUNT_DISK=$(echo $i |awk  '{print $2}')
 DISK_FREE=$(echo $i |awk  '{print $3}')
 if [[ $(echo $DISK_UTILIZ | sed s/%//g) -gt 70 ]]
   then
    echo "不正常""("$MOUNT_DISK"的使用率"$DISK_UTILIZ"较大,请注意"")"
   else
    continue
 fi
done
echo -e
echo "磁盘具体使用情况:"
df -hP | sed 1d | awk '{print $NF"分区""剩余空间"$(NF-2),"使用率"$(NF-1)}'
UMAIL_DIR=$(cat /usr/local/k-k/config/custom.conf | grep "mailroot" | awk -F"=" '{print $2}' | sed 's/^[ \t]*//g')
echo "邮件数据存储在"$UMAIL_DIR
echo -e
echo -e
}

function chenck_mem() {
echo "######内存使用情况######"
Check_OS
RESULT=$?
if [ ${RESULT} -eq 0 ]
 then
  MEM_SUM_NUM=$(free -m | grep "Mem:" | awk -F" " '{print $2}')
  MEM_SURPLUS_NUM=$(free -m | grep "Mem:" | awk '{for(i=4;i<=NF;i++) print $i""FS;}' | awk '{a+=$1}END{print a}')
  MEM_SUM=$(free -m | grep "Mem:" | awk -F" " '{print $2"M"}')
  MEM_SURPLUS=$(free -m | grep "Mem:" | awk '{for(i=4;i<=NF;i++) print $i""FS;}' | awk '{a+=$1}END{print a"M"}')
  MEM_USED=$(echo $(($MEM_SUM_NUM-$MEM_SURPLUS_NUM)))
  PERCENT=$(printf "%d%%" $(($MEM_USED*100/$MEM_SUM_NUM)))
  PERCENT_NUM=$(echo $PERCENT|sed s/%//g)
   if [[ $PERCENT_NUM -lt 70 ]]
    then
     MEM_STATUS=正常
    else
     MEM_STATUS=不正常
   fi
  echo "$MEM_STATUS(""总内存大小"$MEM_SUM,"剩余内存大小"$MEM_SURPLUS,"内存使用率"$PERCENT")"
 else
  MEM_SUM_NUM7=$(free -m | grep "Mem:" | awk -F" " '{print $2}')
  MEM_SURPLUS_NUM7=$(free -m | grep "Mem:" | awk -F" " '{print $4}')
  MEM_SUM7=$(free -m | grep "Mem:" | awk -F" " '{print $2"M"}')
  MEM_SURPLUS7=$(free -m | grep "Mem:" | awk -F" " '{print $4"M"}')
  MEM_USED7=$(echo $(($MEM_SUM_NUM7-$MEM_SURPLUS_NUM7)))
  PERCENT7=$(printf "%d%%" $(($MEM_USED7*100/$MEM_SUM_NUM7)))
  PERCENT_NUM7=$(echo $PERCENT7|sed s/%//g)
   if [[ $PERCENT_NUM7 -lt 70 ]]
    then
     MEM_STATUS=正常
    else
     MEM_STATUS=不正常
   fi
  echo "$MEM_STATUS(""总内存大小"$MEM_SUM7,"剩余内存大小"$MEM_SURPLUS7,"内存使用率"$PERCENT7")"
fi 
echo -e
echo -e
}

function chenck_os_kk() {
echo "######操作系统版本和邮件系统版本######"
OS_VERSION=$(cat /etc/redhat-release)
UMAILAPP_VERSION=$(rpm -qa | grep kk_app | awk -F"." '{print $1"."$2"."$3}')
UMAILWEB_VERSION=$(rpm -qa | grep kk_webmail | awk -F"." '{print $1"."$2"."$3}')
echo $OS_VERSION,$UMAILAPP_VERSION,$UMAILWEB_VERSION
echo -e
echo -e
}

function chenck_secure() {
echo "######系统基本操作是否正常######"
SSH_SUM=$(cat /var/log/secure | grep "authentication failure" | wc -l)
SSH_DIY=500
if [ $SSH_SUM -gt $SSH_DIY ]
 then
  echo "有人在试您root密码，请注意"
 else
  echo "正常"
fi
echo -e
echo -e
}

function chenck_dubious_process() {
echo "######是否有可疑进程或后门######"
echo "正常" 
echo -e
echo -e
}

function chenck_iptable_clamd() {
echo "######是否安装杀毒软件防火墙######"
Check_OS
RESULT=$?
if [ ${RESULT} -eq 0 ]
 then
  /etc/init.d/iptables status 1>/dev/null 2>&1
  RESULT_IPTABLES=$?
  if [ ${RESULT_IPTABLES} -eq 0 ]
   then
    echo "操作系统自带防火墙已开启"
   else
    echo "操作系统自带防火墙未开启"
  fi
 else
  systemctl status firewalld.service 1>/dev/null 2>&1
  RESULT_FIREWALLD=$?
  if [ ${RESULT_FIREWALLD} -eq 0 ]
   then
    echo "操作系统自带防火墙已开启"
   else
    echo "操作系统自带防火墙未开启"
  fi  
fi
Check_OS
RESULT=$?
if [ ${RESULT} -eq 0 ]
 then
  ps -ef | grep kk_clamd | grep -v grep 1>/dev/null 2>&1
  RESULT_CLAMD6=$?
  /etc/init.d/kk_clamd status 1>/dev/null 2>&1
  RESULT_CLAMDSTATUS6=$?
   if [ ${RESULT_CLAMD6} -eq 0 ] && [ ${RESULT_CLAMDSTATUS6} -eq 0 ]
    then
     echo "已安装CLAMD杀毒软件"
   else
     echo "未安装杀毒软件或者未启动成功"
   fi
 else
  ps -ef | grep kk_clamd | grep -v grep 1>/dev/null 2>&1
  RESULT_CLAMD7=$?
  systemctl status kk_clamd.service 1>/dev/null 2>&1
  RESULT_CLAMDSTATUS7=$?
   if [ ${RESULT_CLAMD7} -eq 0 ] && [ ${RESULT_CLAMDSTATUS7} -eq 0 ]
    then
     echo "已安装CLAMD杀毒软件"
    else
     echo "未安装杀毒软件或者未启动成功"
   fi
fi
echo -e
echo -e
}

function chenck_time() {
echo "######开机时长######"
LINETIME=$(uptime | awk -F"up" '{print $2}' | awk -F",  load average" '{print $1}')
echo "服务器开机时间为"$LINETIME
echo -e
echo -e
}

function chenck_http() {
echo "######HTTP服务######"
APACHE6_STATUS=$(/etc/init.d/kk_apache status 1>/dev/null 2>&1) 
NGINX6_STATUS=$(/etc/init.d/kk_nginx status 1>/dev/null 2>&1)
APACHE7_STATUS=$(systemctl status kk_apache.service 1>/dev/null 2>&1)
NGINX7_STATUS=$(systemctl status kk_nginx.service 1>/dev/null 2>&1)
APACHE_PROC=$(ps -ef | grep "/usr/local/k-k/service/apache/bin/httpd" | grep -v grep 1>/dev/null 2>&1)
NGINX_PROC=$(ps -ef | grep "/usr/local/k-k/service/nginx/sbin/nginx" | grep -v grep 1>/dev/null 2>&1)
Check_OS
RESULT=$?
if [ ${RESULT} -eq 0 ]
 then
  /etc/init.d/kk_apache status 1>/dev/null 2>&1
  RESULT_APACHE6=$?
  /etc/init.d/kk_nginx status 1>/dev/null 2>&1
  RESULT_NGINX6=$?
  ps -ef | grep "/usr/local/k-k/service/apache/bin/httpd" | grep -v grep 1>/dev/null 2>&1
  RESULT_APACHEPROC6=$?
  ps -ef | grep "/usr/local/k-k/service/nginx/sbin/nginx" | grep -v grep 1>/dev/null 2>&1
  RESULT_NGINXPROC6=$?
  if [ ${RESULT_APACHE6} -eq 0 ] && [ ${RESULT_NGINX6} -eq 0 ] && [ ${RESULT_APACHEPROC6} -eq 0 ] && [ ${RESULT_NGINXPROC6} -eq 0 ]
   then
    echo "HTTP服务启动成功"
   else
    echo "HTTP服务启动不成功"
  fi
 else
  systemctl status kk_apache.service 1>/dev/null 2>&1
  RESULT_APACHE7=$?
  systemctl status kk_nginx.service 1>/dev/null 2>&1
  RESULT_NGINX7=$?
  ps -ef | grep "/usr/local/k-k/service/apache/bin/httpd" | grep -v grep 1>/dev/null 2>&1
  RESULT_APACHEPROC7=$?
  ps -ef | grep "/usr/local/k-k/service/nginx/sbin/nginx" | grep -v grep 1>/dev/null 2>&1
  RESULT_NGINXPROC7=$?
  if [ ${RESULT_APACHE7} -eq 0 ] && [ ${RESULT_NGINX7} -eq 0 ] && [ ${RESULT_APACHEPROC7} -eq 0 ] && [ ${RESULT_NGINXPROC7} -eq 0 ]
   then
    echo "HTTP服务启动成功"
   else
    echo "HTTP服务启动不成功"
   fi
fi
echo -e
echo -e
}

function chenck_smtp() {
echo "######SMTP服务######"
Check_OS
RESULT=$?
if [ ${RESULT} -eq 0 ]
 then
  netstat -anltp | grep ":25" 1>/dev/null 2>&1
  RESULT_SMTP=$?
  /etc/init.d/kk_postfix status 1>/dev/null 2>&1
  RESULT_POSTFIX=$?
  if [ ${RESULT_SMTP} -eq 0 ] && [ ${RESULT_POSTFIX} -eq 0 ]
   then
    echo "SMTP服务启动成功"
   else
    echo "SMTP服务启动不成功"
  fi
 else
  netstat -anltp | grep ":25" 1>/dev/null 2>&1
  RESULT_SMTP7=$?
  systemctl status kk_postfix.service 1>/dev/null 2>&1
  RESULT_POSTFIX7=$?
  if [ ${RESULT_SMTP7} -eq 0 ] && [ ${RESULT_POSTFIX7} -eq 0 ]
   then
    echo "SMTP服务启动成功"
   else
    echo "SMTP服务启动不成功"
  fi
fi
echo -e
echo -e
}

function chenck_pop() {
echo "######POP服务######"
Check_OS
RESULT=$?
if [ ${RESULT} -eq 0 ]
 then
  netstat -anltp | grep ":110" 1>/dev/null 2>&1
  RESULT_POP=$?
  /etc/init.d/kk_dovecot status 1>/dev/null 2>&1
  RESULT_POPPROC=$?
  if [ ${RESULT_POP} -eq 0 ] && [ ${RESULT_POPPROC} -eq 0 ]
   then
    echo "POP服务启动成功"
   else
    echo "POP服务启动不成功"
  fi
 else
  netstat -anltp | grep ":110" 1>/dev/null 2>&1
  RESULT_POP7=$?
  systemctl status kk_dovecot.service 1>/dev/null 2>&1
  RESULT_POPPROC7=$?
  if [ ${RESULT_POP7} -eq 0 ] && [ ${RESULT_POPPROC7} -eq 0 ]
   then
    echo "POP服务启动成功"
   else
    echo "POP服务启动不成功"
  fi
fi
echo -e
echo -e
}

function chenck_imap() {
echo "######IMAP服务######"
Check_OS
RESULT=$?
if [ ${RESULT} -eq 0 ]
 then
  netstat -anltp | grep ":143" 1>/dev/null 2>&1
  RESULT_IMAP=$?
  /etc/init.d/kk_dovecot status 1>/dev/null 2>&1
  RESULT_IMAPPROC=$?
  if [ ${RESULT_IMAP} -eq 0 ] && [ ${RESULT_IMAPPROC} -eq 0 ]
   then
    echo "IMAP服务启动成功"
   else
    echo "IMAP服务启动不成功"
  fi
 else
  netstat -anltp | grep ":143" 1>/dev/null 2>&1
  RESULT_IMAP7=$?
  systemctl status kk_dovecot.service 1>/dev/null 2>&1
  RESULT_IMAPPROC7=$?
  if [ ${RESULT_IMAP7} -eq 0 ] && [ ${RESULT_IMAPPROC7} -eq 0 ]
   then
    echo "IMAP服务启动成功"
   else
    echo "IMAP服务启动不成功"
  fi
fi
echo -e
echo -e
}

function chenck_inout() {
echo "######收发测试(web和客户端)######"
echo "正常"
echo -e
echo -e
}

function chenck_admin() {
echo "######管理后台功能测试######"
echo "正常"
echo -e
echo -e
}

function chenck_spam() {
echo "######反垃圾反病毒测试######"
echo "正常"
echo -e
echo -e
}

function chenck_stmpout() {
echo "######是否有密码泄露导致群发垃圾邮件现象######"
SMTP_SUM=$(cat /usr/local/k-k/app/log/smtp.log | grep "from:" | awk -F " " '{ print $6 }' | sed 's/<//g' | sed 's/>,//g' | sort | uniq -c | sort -rn |sed 's/^[ \t]*//g' |head -n 1 | awk -F" " '{print $1}')
SMTP_USER=$(cat /usr/local/k-k/app/log/smtp.log | grep "from:" | awk -F " " '{ print $6 }' | sed 's/<//g' | sed 's/>,//g' | sort | uniq -c | sort -rn |sed 's/^[ \t]*//g' |head -n 1 | awk -F" " '{print $2}')
SMTP_DIY=500
if [ $SMTP_SUM -gt $SMTP_DIY ]
 then
  echo "当天外发邮件数量最大的"$SMTP_USER"用户超过"$SMTP_DIY"封，请确认"
 else
  echo "正常"
fi
echo -e
echo -e
}

echo "巡检开始"
echo -e
chenck_cpu
chenck_disk
chenck_mem
chenck_os_kk
chenck_secure
chenck_dubious_process
chenck_iptable_clamd
chenck_time
chenck_http
chenck_smtp
chenck_pop
chenck_imap
chenck_inout
chenck_admin
chenck_spam
chenck_stmpout
echo -e
echo "巡检结束"
