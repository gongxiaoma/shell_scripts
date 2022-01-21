#!/bin/bash
#author:gxm
#date:2018-05-15
#version:1.1

#运行脚本前请先修改相关参数，比如7-13、220-224、227-231、252行信息
#此脚本有使用到帐号密码ssh远程连接到另一台机器的，这种方式可以替换成免密钥认证
HOSTNAME1="drbd1.db.com"
HOSTNAME2="drbd2.db.com"
MOUNTDIR="/store"
MAILFROM="test@163.com"
SMTPSERVER="smtp.163.com"
SMTPUSER="test@163.com"
SMTPPASSWD="123456"
CURRDATE=$(date "+%Y-%m-%d %H:%M:%S")
DRBD_HALOG=/var/log/drbd_ha.log
CURRENTHOST_HEARTBEAT_STATUS=/tmp/currenthost_heartbeat_status.txt
OTHERHOST_HEARTBEAT_STATUS=/tmp/otherhost_heartbeat_status.txt
CURRENTHOST_DRBD_DETAILED=/tmp/currenthost_drbd_detailed.txt
OTHERHOST_DRBD_DETAILED=/tmp/otherhost_drbd_detailed.txt
CURRENTHOST_DISK=/tmp/currenthost_disk.txt
OTHERHOST_DISK=/tmp/otherhost_disk.txt

echo "">$DRBD_HALOG


#退出脚本
function force_exit()
{
   echo "$CURRDATE: 脚本意外退出!" | tee -a $DRBD_HALOG
   echo
   exit 1;
}



# 输出日志提示
function output_notify()
{
   echo $CURRDATE：$1 | tee -a $DRBD_HALOG
}



# 输出错误提示
function output_error()
{
   echo "$CURRDATE：[ERROR] >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>" | tee -a $DRBD_HALOG
   echo "$CURRDATE：[ERROR] "$1 | tee -a $DRBD_HALOG
   echo "$CURRDATE：[ERROR] <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<" | tee -a $DRBD_HALOG
}



#颜色函数
function echo_colour()
{
	if [ $1 -eq 0 ]
	 then
		echo -e $CURRDATE："\033[41;37m ${2} \033[0m" | tee -a $DRBD_HALOG
		return 0
	fi

	if [ $1 -eq 1 ]
	 then
		echo -e $CURRDATE："\033[43;37m ${2} \033[0m" | tee -a $DRBD_HALOG
		return 0
	fi

	if [ $1 -eq 2 ]
	 then
		echo -e $CURRDATE："\033[47;30m ${2} \033[0m" | tee -a $DRBD_HALOG
		return 0
	fi
	
	if [ $1 -eq 3 ]
	 then
		echo -e $CURRDATE："\033[34m ${2} \033[0m" | tee -a $DRBD_HALOG
		return 0
	fi
	
	if [ $1 -eq 4 ]
	 then
		echo -e $CURRDATE："\033[31m ${2} \033[0m" | tee -a $DRBD_HALOG
		return 0
	fi
}



#检测root用户
function check_user_root()
{
   if [ `id -u` -eq 0 ]
    then
     output_notify "当前是root账号，正在执行脚本"
    else
     output_error "当前是非root账号，退出脚本"
     force_exit
   fi
}
check_user_root



#检测操作系统版本
function check_os()
{
if uname -a | grep 'el5' >/dev/null 2>&1
 then
    SYS_RELEASE="el5"
 elif uname -a | grep 'el7' >/dev/null 2>&1
  then
    SYS_RELEASE="el7"
 else
    SYS_RELEASE="el6"
fi
}



#安装配置mailx客户端工具
function mailx()
{
yum -y install mailx
cat >> /etc/mail.rc  << EOF
set from=$MAILFROM
set smtp=$SMTPSERVER
set smtp-auth-user=$SMTPUSER
set smtp-auth-password=$SMTPPASSWD
set smtp-auth=login
EOF
}



#检测mailx是否安装，如果没安装安装下
function check_mailx_program()
{
  check_os
  if [ $SYS_RELEASE = el6 ]
   then
    if [ ! -e /bin/mailx ]
     then
      echo "现在安装mailx工具!"
      mailx
    fi
  elif [ $SYS_RELEASE = el7 ] 
   then
    if [ ! -e /usr/bin/mailx ]
     then
      echo "现在安装mailx工具!"
      mailx
    fi
  else
   echo "此脚本只适用于centos6和7版本"
  fi
}
check_mailx_program



#发送邮件函数的帮助
function sendmailhelp()
{
   echo "eg: $0 [Subject] [address] [content_file] [file]"
   echo ""
   exit 1
}



#具体发送邮件函数
#$1为邮件标题，$2为收件人邮箱地址，$3为邮件内容，$4为附件（不是必须）
function sendmail()
{
if [ ! -n "$1" ]
 then
    sendmailhelp
fi

cDate=`date +%Y%m%d`
if [ ! -n "$2" ]
 then
    sendmailhelp
 else
    mail_to=$2
    echo "      Send Mail to ${mail_to}"
fi

if [ ! -n "$4" ]
 then
    mail -s $1 ${mail_to}<$3
 else
    mail -s $1 -a $4 ${mail_to}<$3
fi
}



#检查操作系统版本
function check_os()
{
if uname -a | grep 'el5' >/dev/null 2>&1
 then
    SYS_RELEASE="el5"
 elif uname -a | grep 'el7' >/dev/null 2>&1
  then
    SYS_RELEASE="el7"
 else
    SYS_RELEASE="el6"
fi
}



#获取当前主机名并给另外一台主机赋予相关远程信息
CURRENT_HOSTNAME=`hostname`
if [ $CURRENT_HOSTNAME = "$HOSTNAME1" ]
then
 output_notify "当前服务器主机名为$CURRENT_HOSTNAME"
 OTHER_HOST="192.168.40.52"
 OTHER_PROT="22"
 OTHER_USER="root"
 OTHER_PASSWD="123456"
elif [ $CURRENT_HOSTNAME = "$HOSTNAME2" ]
 then
 output_notify "当前服务器主机名为$CURRENT_HOSTNAME"
 OTHER_HOST="192.168.40.54"
 OTHER_PROT="22"
 OTHER_USER="root"
 OTHER_PASSWD="123456"
else
 echo "您主机名不符合要求"
fi



#判断是否安装了expect工具
if [ ! -e /usr/bin/expect ]
  then
   echo "现在安装expect工具!"
   yum -y install expect
fi


#远程到另外一台主机的函数
function ssh_otherhost()
{
/usr/bin/expect<<EOF
spawn ssh -t -p "$OTHER_PROT" $OTHER_USER@$OTHER_HOST "$1" 
expect {
"*\(yes\/no\)?" { send "yes\r"; exp_continue}
"*password:" { send "$OTHER_PASSWD\r" }
}
expect eof
EOF
}



#将查询服务状态导出到txt文件中
function outtxt()
{
  $1 > $2
  ssh_otherhost "$1" > $3
}

check_os
if [ $SYS_RELEASE = el6 ]
 then
  outtxt "/etc/init.d/heartbeat status" "$CURRENTHOST_HEARTBEAT_STATUS" "$OTHERHOST_HEARTBEAT_STATUS"
  outtxt "cat /proc/drbd" "$CURRENTHOST_DRBD_DETAILED" "$OTHERHOST_DRBD_DETAILED"
  outtxt "df -h" "$CURRENTHOST_DISK" "$OTHERHOST_DISK"
 elif [ $SYS_RELEASE = el7 ]
 then
  outtxt "systemctl status heartbeat" "$CURRENTHOST_HEARTBEAT_STATUS" "$OTHERHOST_HEARTBEAT_STATUS"
  outtxt "cat /proc/drbd" "$CURRENTHOST_DRBD_DETAILED" "$OTHERHOST_DRBD_DETAILED"
  outtxt "df -h" "$CURRENTHOST_DISK" "$OTHERHOST_DISK"
 else
  echo "此脚本只支持centos6和7"
fi



#在导出的heartbeat状态文件中查找指定关键字的函数
function server_code()
{
cat $1 | egrep "$2" >/dev/null 2>&1
reslut=$?
if [ $reslut -eq 0 ]
 then
  output_notify "$3"
  return 0
 else
  output_error "$4"
  return 1
fi
}  



#在导出的disk文件中查找指定关键字的函数
function disk_mount_code()
{
cat $1 | egrep "$2" >/dev/null 2>&1
reslut=$?
if [ $reslut -eq 0 ]
 then
  output_notify "$3"
  return 0
 else
  output_notify "$4"
  return 1
fi
}  



#drbd的主从状态函数
function drbd_status()
{
currenthost_drbd=`cat $CURRENTHOST_DRBD_DETAILED | grep "ro:"|awk -F" " '{print $3}'`
otherhost_drbd=`cat $OTHERHOST_DRBD_DETAILED | grep "ro:"|awk -F" " '{print $3}'`
if ([[ $currenthost_drbd = "ro:Secondary/Primary" ]] && [[ $otherhost_drbd = "ro:Primary/Secondary" ]]) || ([[ $currenthost_drbd = "ro:Primary/Secondary" ]] && [[ $otherhost_drbd = "ro:Secondary/Primary" ]])
 then
  output_notify "drbd主从状态正常"
  return 0
 else
  output_error "drbd主从状态异常，请详细检查或参考$DRBD_HALOG日志"
  return 1
fi
}



#drbd的同步状态函数
function drbd_status_update()
{
currenthost_drbd_update=`cat $CURRENTHOST_DRBD_DETAILED | grep "ro:"|awk -F" " '{print $4}'`
otherhost_drbd_update=`cat $OTHERHOST_DRBD_DETAILED | grep "ro:"|awk -F" " '{print $4}'`
if [[ $currenthost_drbd_update = "ds:UpToDate/UpToDate" ]] && [[ $otherhost_drbd_update = "ds:UpToDate/UpToDate" ]]
 then
  output_notify "drbd同步状态正常"
  return 0
 else
  output_error "drbd同步状态异常，请详细检查或参考$DRBD_HALOG日志"
  return 1
fi
}




#判断两台服务器heartbeat运行情况
check_os
if [ $SYS_RELEASE = el6 ]
 then
  server_code "$CURRENTHOST_HEARTBEAT_STATUS" "is running" "当前服务器heartbeat服务运行正常" "当前服务器heartbeat服务异常，请检查"
  currenthost_heartbeat_code=$?
  server_code "$OTHERHOST_HEARTBEAT_STATUS" "is running" "另一台服务器heartbeat服务运行正常" "另一台服务器heartbeat服务异常，请检查"
  otherhost_heartbeat_code=$?
 elif [ $SYS_RELEASE = el7 ]
 then
  server_code "$CURRENTHOST_HEARTBEAT_STATUS" "Active.*active.*running" "当前服务器heartbeat服务运行正常" "当前服务器heartbeat服务异常，请检查"
  currenthost_heartbeat_code=$?
  server_code "$OTHERHOST_HEARTBEAT_STATUS" "Active.*active.*running" "另一台服务器heartbeat服务运行正常" "另一台服务器heartbeat服务异常，请检查"
  otherhost_heartbeat_code=$?
 else
  echo "此脚本只支持centos6和7"
fi

if [ $currenthost_heartbeat_code -eq 0 ] && [ $otherhost_heartbeat_code -eq 0 ] 
 then
  echo_colour 1 "恭喜，两台服务器heartbeat服务均运行正常"
 else
  output_error "heartbeat服务异常，请详细检查或参考$DRBD_HALOG日志"
  sendmail "heartbeat服务异常，详细见邮件正文" gxm@comingchina.com $DRBD_HALOG
fi



#判断两台服务器挂载磁盘情况
disk_mount_code "$CURRENTHOST_DISK" "$MOUNTDIR" "当前服务器$MOUNTDIR挂载了" "当前服务器$MOUNTDIR没挂载"
currenthost_disk_code=$?
disk_mount_code "$OTHERHOST_DISK" "$MOUNTDIR" "另一台服务器$MOUNTDIR挂载了" "另一台服务器$MOUNTDIR没挂载"
otherhost_disk_code=$?
if ([ $currenthost_disk_code -eq 0 ] && [ $otherhost_disk_code -eq 1 ]) || ([ $currenthost_disk_code -eq 1 ] && [ $otherhost_disk_code -eq 0 ]) 
 then
    echo_colour 1 "恭喜，$MOUNTDIR挂载正常"
 else
  output_error "$MOUNTDIR挂载异常，请详细检查或参考$DRBD_HALOG日志"
  sendmail "$MOUNTDIR挂载异常，详细见邮件正文" gxm@comingchina.com $DRBD_HALOG
fi



#判断两台服务器drbd运行情况
drbd_status
drbd_status_code=$?
drbd_status_update
drbd_status_update_code=$?
if [ $drbd_status_code -eq 0 ] && [ $drbd_status_update_code -eq 0 ]
 then
  echo_colour 1 "恭喜，两台服务器drbd运行正常"
 else
  output_error "drbd运行不正常，请详细检查或参考$DRBD_HALOG日志"
  sendmail "drbd服务异常，详细见邮件正文" gxm@comingchina.com $DRBD_HALOG
fi
