#!/bin/bash
#Date 2016-08-24
#Author:GXM	
#Mail:gxm@comingchina.com
#Function:fail2ban deploy
#Version:1.1
#####################################################################
# 检查root权限
echo
echo "############################################################"
echo "检查当前用户是否为root权限"
if [ `id -u` -eq 0 ];then
 echo "root用户!"
else
 echo "非root用户!"
 exit 2
fi

#####################################################################
# 变量区
FAIL2BAN_DOWNLOAD=http://www.comingchina.com/download/soft/other/fail2ban.tar.gz
OUTIP=$(curl -s http://members.3322.org/dyndns/getip)

#####################################################################
# 函数区
# 检测 wget 程序
check_wget_program()
{
    [ -e /usr/bin/wget ] && return 0
    echo "Error: Can't found wget command!"
    exit 2
}

# 检测 tar 程序
check_tar_program()
{
    [ -e /bin/tar ] && return 0
    echo "Error: Can't found tar command!"
    exit 2
}

# 检测 yum 程序
check_yum_program()
{
    [ -e /usr/bin/yum ] && return 0
    echo "Error: Can't found yum command!"
    exit 2
}

#####################################################################
# 执行区
echo
echo "############################################################"
echo "同步时间（北京邮电大学）"
yum -y install ntpdate
RESULT=$?
if [ ${RESULT} -ne 0 ]; then
    echo "安装ntpdate出错"
	exit 2
fi

service ntpd stop
service ntpdate stop
/usr/sbin/ntpdate  202.112.10.60 #北京邮电大学
RESULT=$?
if [ ${RESULT} -ne 0 ]; then
    echo "同步时间出错，正在尝试同步其他时间服务器"
	/usr/sbin/ntpdate  ntp.sjtu.edu.cn   #上海交通大学网络中心NTP服务器地址
    /usr/sbin/ntpdate  s1b.time.edu.cn   #清华大学
    /usr/sbin/ntpdate  s1c.time.edu.cn   #北京大学
    /usr/sbin/ntpdate  s2g.time.edu.cn   #华东南地区网络中心
    /usr/sbin/ntpdate  time.windows.com  #其他
	else
    echo "同步时间服务器成功"
fi

echo
echo "############################################################"
echo "安装wget包"
check_yum_program
yum -y install wget
RESULT=$?
if [ ${RESULT} -ne 0 ]; then
    echo "安装wget出错"
	exit 2
fi

echo
echo "############################################################"
echo "下载fail2ban安装包"
check_wget_program
wget -O /tmp/fail2ban.tar.gz -o /dev/null "${FAIL2BAN_DOWNLOAD}"
RESULT=$?
if [ ${RESULT} -ne 0 ]; then
    echo "下载出错"
	exit 2
fi

echo
echo "############################################################"
echo "解压fail2ban安装包"
check_tar_program
tar -zxvf /tmp/fail2ban.tar.gz -C /tmp/
RESULT=$?
if [ ${RESULT} -ne 0 ]; then
    echo "解压出错"
	exit 2
fi

echo
echo "############################################################"
echo "开始安装fail2ban和相关依赖包"
yum -y install logwatch gamin
RESULT=$?
if [ ${RESULT} -ne 0 ]; then
    echo "安装logwatch和gamin出错"
	exit 2
fi

yum -y localinstall /tmp/python-inotify-0.9.1-1.1.el6.noarch.rpm
RESULT=$?
if [ ${RESULT} -ne 0 ]; then
    echo "安装python-inotify出错"
	exit 2
fi

yum -y localinstall /tmp/fail2ban-0.8.14-2.el6.noarch.rpm
RESULT=$?
if [ ${RESULT} -ne 0 ]; then
    echo "安装fail2ban出错"
	exit 2
fi

echo
echo "############################################################"
echo "拷贝配置文件"
cp -f /tmp/fail2ban.conf /etc/fail2ban/
RESULT=$?
if [ ${RESULT} -ne 0 ]; then
    echo "拷贝文件出错"
	exit 2
fi
cp -f /tmp/jail.conf /etc/fail2ban/
RESULT=$?
if [ ${RESULT} -ne 0 ]; then
    echo "拷贝文件出错"
	exit 2
fi
cp -f /tmp/kk.conf /etc/fail2ban/filter.d/
RESULT=$?
if [ ${RESULT} -ne 0 ]; then
    echo "拷贝文件出错"
	exit 2
fi

echo
echo "############################################################"
echo "增加出口IP地址为信任IP地址"
sed -i '32s/$/ '${OUTIP}'/' /etc/fail2ban/jail.conf
RESULT=$?
if [ ${RESULT} -ne 0 ]; then
    echo "增加出口IP地址为信任IP地址出错"
	exit 2
fi

echo
echo "############################################################"
echo "重启fail2ban服务"
/etc/init.d/fail2ban restart
RESULT=$?
if [ ${RESULT} -ne 0 ]; then
    echo "启动服务错误"
	exit 2
fi

echo
echo "############################################################"
echo "开机自启动"
chkconfig fail2ban on
RESULT=$?
if [ ${RESULT} -ne 0 ]; then
    echo "开机自启动错误"
	exit 2
fi

exit 0


