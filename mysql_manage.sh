#!/bin/bash
#author:gxm
#date:2018-05-15
#version:1.1

CURRDATE=$(date "+%Y-%m-%d %H:%M:%S")
MYSQLMANAGELOG=/usr/local/k-k/log/app/mysql_manage.log
NUM_VERSION=$(uname -r)
DATABASENAME=kk
MYSQLUSER=kk
MYSQLPASS=`cat /usr/local/k-k/config/custom.conf | grep -w pass | awk -F"= " '{print $NF}'`
MYSQLBIN=/usr/local/k-k/service/mysql/bin/mysql
MYSQLDUMPBIN=/usr/local/k-k/service/mysql/bin/mysqldump
MYSQLCHECKBIN=/usr/local/k-k/service/mysql/bin/mysqlcheck
UMAILMYSQLSERVICE=kk_mysqld
UMAILCONF=/usr/local/k-k/config/custom.conf
UMAILSERVICE="kk_app kk_nginx kk_apache kk_dovecot kk_redis kk_postfix"

#输出脚本用法
function output_usage()
{   
   echo
   echo "#[USAGE] >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
   echo "sh mysql_manage.sh login          登录mysql命令控制台"
   echo "sh mysql_manage.sh bak            备份数据库"
   echo "sh mysql_manage.sh restore        还原数据库(/root/kkdatabase.sql.gz)"
   echo "sh mysql_manage.sh table_myisam   哪些表是myisam引擎"
   echo "sh mysql_manage.sh table_innodb   哪些表是innodb引擎"
   echo "sh mysql_manage.sh table_status   查看所有表状态"
   echo "sh mysql_manage.sh table_size     查看所有表的大小"
   echo "sh mysql_manage.sh table_repair   检测并修复问题表"
   echo "#[USAGE] <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<"
}


#退出脚本
function force_exit()
{
   echo "$CURRDATE: 脚本意外退出!" | tee -a $MYSQLMANAGELOG
   echo
   exit 1;
}


# 输出日志提示
function output_notify()
{
   echo $CURRDATE：$1 | tee -a $MYSQLMANAGELOG
}


# 输出错误提示
function output_error()
{
   echo "$CURRDATE：[ERROR] >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>" | tee -a $MYSQLMANAGELOG
   echo "$CURRDATE：[ERROR] "$1 | tee -a $MYSQLMANAGELOG
   echo "$CURRDATE：[ERROR] <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<" | tee -a $MYSQLMANAGELOG
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
   [[ $NUM_VERSION =~ el6 ]] && return 0||return 1
}


#安装配置mailx客户端工具
function mailx()
{
yum -y install mailx
cat >> /etc/mail.rc  << EOF
set from="kktest@163.com"
set smtp=smtp.163.com
set smtp-auth-user=kktest@163.com
set smtp-auth-password=123456
set smtp-auth=login
EOF
}


#检测mailx是否安装，如果没安装安装下
function check_mailx_program()
{
  check_os
  RESULT=$?
  if [ ${RESULT} -eq 0 ]
   then
    if [ ! -e /bin/mailx ]
     then
      echo "现在安装mailx工具!"
      mailx
    fi
   else
    if [ ! -e /usr/bin/mailx ]
     then
      echo "现在安装mailx工具!"
      mailx
    fi
  fi
}


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
if [ ! -n "$1" ] ; then
    sendmailhelp
fi

cDate=`date +%Y%m%d`
if [ ! -n "$2" ] ; then
    sendmailhelp
else
    mail_to=$2
    echo "      Send Mail to ${mail_to}"

fi

if [ ! -n "$4" ] ; then
    mail -s $1 ${mail_to}<$3
else
    mail -s $1 -a $4 ${mail_to}<$3
fi
}


#检测mysql是否允许，如果没允许，尝试启动服务
function check_mysqlruning() {
   check_os
   RESULT=$?
   if [ ${RESULT} -eq 0 ]
    then
     /etc/init.d/$UMAILMYSQLSERVICE status >/dev/null 2>&1
     RESULT=$?
     if [ ${RESULT} -ne 0 ]
      then
       output_error "$UMAILMYSQLSERVICE服务没有运行，现在尝试自动启动"
       /etc/init.d/$UMAILMYSQLSERVICE start >/dev/null 2>&1
       /etc/init.d/$UMAILMYSQLSERVICE status >/dev/null 2>&1
       RESULT=$?
       if [ ${RESULT} -eq 0 ]
        then
         output_notify "$UMAILMYSQLSERVICE服务自动启动成功"
        else
         output_error "$UMAILMYSQLSERVICE服务顽强的启动不成功"
         force_exit
       fi
     fi
   else
     systemctl status $UMAILMYSQLSERVICE >/dev/null 2>&1
     RESULT=$?
     if [ ${RESULT} -ne 0 ]
      then
       output_error "$UMAILMYSQLSERVICE服务没有运行，现在尝试自动启动"
       systemctl start $UMAILMYSQLSERVICE >/dev/null 2>&1
       systemctl status $UMAILMYSQLSERVICE >/dev/null 2>&1
       RESULT=$?
       if [ ${RESULT} -eq 0 ]
        then
         output_notify "$UMAILMYSQLSERVICE服务自动启动成功"
        else
         output_error "$UMAILMYSQLSERVICE服务顽强的启动不成功"
         force_exit
       fi
     fi
  fi
}
check_mysqlruning
TABLES=$($MYSQLBIN -u $MYSQLUSER -p`cat $UMAILCONF | grep -w pass | awk -F"= " '{print $NF}'` $DATABASENAME -e "show table status from kk where Engine='MyISAM'" | awk '{print $1}' | sed 1d)
check_mailx_program

#case函数
case $1 in
    "login")
        $MYSQLBIN -u $MYSQLUSER -p$MYSQLPASS
        ;;    
    "bak")
        $MYSQLDUMPBIN -u $MYSQLUSER -p$MYSQLPASS --databases $DATABASENAME |gzip>/root/kkdatabase.sql.gz
        output_notify "数据库备份成功，路径为/root/kkdatabase.sql.gz"
        ;;    
    "restore")
        for i in $UMAILSERVICE;do /etc/init.d/$i stop;done
        gunzip /root/kkdatabase.sql.gz
        $MYSQLBIN -u$MYSQLUSER -p$MYSQLPASS $DATABASENAME </root/kkdatabase.sql
        echo -e
        output_notify "数据库还原成功"
        echo -e
        for i in $UMAILSERVICE;do /etc/init.d/$i start;done
        ;; 
    "table_myisam")
        $MYSQLBIN -u $MYSQLUSER -p$MYSQLPASS $DATABASENAME -e "show table status from $DATABASENAME where Engine='MyISAM'"
        ;; 
    "table_innodb")
        $MYSQLBIN -u $MYSQLUSER -p$MYSQLPASS $DATABASENAME -e "show table status from $DATABASENAME where Engine='InnoDB'"
        ;;    
    "table_status")
        $MYSQLCHECKBIN -c $DATABASENAME -u$MYSQLUSER -p$MYSQLPASS
        ;;
    "table_size")
        $MYSQLBIN -u $MYSQLUSER -p$MYSQLPASS $DATABASENAME -e "select table_name, (data_length+index_length)/1024/1024 as total_mb, table_rows from information_schema.tables where table_schema='$DATABASENAME';"
        ;;
    "table_repair")
#	      echo ">>>>>>>>>> tables::   ${TABLES}"
        for table_name in $TABLES
        do
	       echo "check ${table_name}"
         check_result=$($MYSQLCHECKBIN -c $DATABASENAME $table_name -u$MYSQLUSER -p$MYSQLPASS|awk '{print $NF}')
         if [ "$check_result" = "OK" ]
          then
           continue 2
          else
           #vim /usr/local/k-k/data/mysql/default/kk/admin.MYD 改这个文件模拟表损坏
           output_error "$table_name表异常，现在进行修复"
           sendmail "$table_name出现异常，现在尝试修复" gxm@comingchina.com $MYSQLMANAGELOG
           $MYSQLCHECKBIN -r $DATABASENAME $table_name -u$MYSQLUSER -p$MYSQLPASS
           check_result=$($MYSQLCHECKBIN -c $DATABASENAME $table_name -u$MYSQLUSER -p$MYSQLPASS|awk '{print $NF}')
           if [ "$check_result" = "OK" ]
            then
             output_notify "[OK] $table_name表修复成功"
             sendmail "恭喜$table_name自动修复成功" gxm@comingchina.com $MYSQLMANAGELOG
           fi
         fi
       done
        ;; 
    *)
        output_usage
        force_exit
        ;;
esac

