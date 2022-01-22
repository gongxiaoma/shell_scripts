#!/bin/bash
#Date 2017-01-11
#Author:GXM	
#Mail:gxm@comingchina.com
#Function:Backup Restore
#Version:1.1
#####################################################################
#交互的时候可以退格
stty erase ^H
# 检查root权限
echo
if [ `id -u` -eq 0 ];then
 echo -e '\033[41;33;1m 请仔细按照提示操作! \033[0m'
else
 echo -e '\033[0;31;1m 对不起，非root帐号无权限操作 \033[0m'
 exit 2
fi
##########################



#####################################################################
# 变量区
searchdir=/data/
maildatadir=/usr/local/k-k/data/mailbox/domain.com/0/
ls -lh $maildatadir | awk '{print $NF}' | sed "s/$/@domain.com/" | sed "1d" > /root/mailbox
##########################



#####################################################################
# 定义用户只能输入1或2
echo -e '\n'
read -p "请输入(以收件人查找按1，以发件人查找按2):  " no12
if [ $no12 -ne 1 ] && [ $no12 -ne 2 ]
then
 echo -e '\n'
 echo -e '\033[0;31;1m 输入错误，请输入1或2 \033[0m'
fi
##########################



#####################################################################
# 当用户输入1的时候，执行下面的代码
if [ $no12 -eq 1 ]; then
 echo -e '\n'
 read -p "请输入(需要查找的收件人，如test1@domain.com):  " from
 grep -w "$from" /root/mailbox
 RESULT=$?
 if [ ${RESULT} -ne 0 ]; then
  echo -e '\033[0;31;1m不存在此邮箱 \033[0m'
  exit -1
 fi
 echo -e '\n'
 read -p "请输入(需要恢复到哪个邮箱，如test2@domain.com):  " destination
 grep -w "$destination" /root/mailbox
 RESULT=$?
 if [ ${RESULT} -ne 0 ]; then
  echo -e '\033[0;31;1m不存在此邮箱 \033[0m'
  exit -1
 fi
 echo -e '\n'
 echo "正在查找恢复邮件:  "
 name=$(echo $destination | awk -F'@' '{print $1}')
 grep -r -i -P "$from" $searchdir  |grep -i To|awk -F"[:]" {'print $1":"$2'}
 grep -r -i -P "$from" $searchdir  |grep -i To|awk -F"[:]" {'print $1":"$2'}|xargs -i cp -pn {} $maildatadir$name/cur/
fi
##########################



#####################################################################
# 当用户输入2的时候，执行下面的代码
if [ $no12 -eq 2 ]; then
 echo -e '\n'
 read -p "请输入(需要查找的发件人，如test1@domain.com):  " fromfa
 grep -w "$fromfa" /root/mailbox
 RESULT=$?
 if [ ${RESULT} -ne 0 ]; then
  echo -e '\033[0;31;1m不存在此邮箱 \033[0m'
  exit -1
 fi
 echo -e '\n'
 read -p "请输入(需要恢复到哪个邮箱，如test2@domain.com):  " destinationfa
 grep -w "$destinationfa" /root/mailbox
 RESULT=$?
 if [ ${RESULT} -ne 0 ]; then
  echo -e '\033[0;31;1m不存在此邮箱 \033[0m'
  exit -1
 fi
 echo -e '\n'
 echo "正在查找恢复邮件:  "
 namefa=$(echo $destinationfa | awk -F'@' '{print $1}')
 if [ $fromfa == $destinationfa ]; then
 grep -r -i -P "$fromfa" $searchdir  |grep -i From|awk -F"[:]" {'print $1":"$2'}
 grep -r -i -P "$fromfa" $searchdir  |grep -i From|awk -F"[:]" {'print $1":"$2'}|xargs -i cp -pn {} $maildatadir$namefa\/.Sent/cur/
 else
 grep -r -i -P "$fromfa" $searchdir  |grep -i From|awk -F"[:]" {'print $1":"$2'}
 grep -r -i -P "$fromfa" $searchdir  |grep -i From|awk -F"[:]" {'print $1":"$2'}|xargs -i cp -pn {} $maildatadir$namefa/cur/
 fi
fi
##########################

