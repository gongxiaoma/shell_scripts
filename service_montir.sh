#/bin/sh
CURRDATE=$(date "+%Y-%m-%d %H:%M:%S")
RESTARTLOG=/usr/local/k-k/log/app/service_restart.log
DEP_RESTART="kk_redis kk_mysqld kk_postfix kk_dovecot"

# 检查root权限
if [ `id -u` -eq 0 ];then
 echo "Running scripts"
else
 echo "非root用户!"
 exit 2
fi

# 检测kk是否在升级
STOPPRO=$(ps -ef | grep "/bin/sh /tmp/._kk_update.sh" | grep -v grep|wc -l)
if [ $STOPPRO -gt 0 ]
 then
  echo "$CURRDATE kk is update,exit servicemon script" >>$RESTARTLOG
  exit 2
fi  


#定义检查操作系统版本的函数
NUM_VERSION=$(uname -r)
function Check_OS(){
[[ $NUM_VERSION =~ el6 ]] && return 0||return 1
}

#检查app服务，如果异常，重启相关服务
check_app(){
Check_OS
RESULT=$?
if [ ${RESULT} -eq 0 ]
 then
   /etc/init.d/kk_app status >/dev/null 2>&1
   RESULT=$?
   if [ ${RESULT} -ne 0 ]; then 
     echo "$CURRDATE dep_app_restart" >>$RESTARTLOG
     /etc/init.d/kk_app stop >/dev/null 2>&1
     sleep 5
     /etc/init.d/kk_app start >/dev/null 2>&1

     for n in ${DEP_RESTART}
     do
      echo "$CURRDATE dep_restart-$n" >>$RESTARTLOG
      /etc/init.d/$n restart >/dev/null 2>&1
     done 
   fi
 else
   systemctl status kk_app >/dev/null 2>&1
   RESULT=$?
   if [ ${RESULT} -ne 0 ]; then
     echo "$CURRDATE dep_app_restart" >>$RESTARTLOG
     systemctl stop kk_app >/dev/null 2>&1
     sleep 5
     systemctl start kk_app >/dev/null 2>&1

     for n in ${DEP_RESTART}
     do
      echo "$CURRDATE dep_restart-$n" >>$RESTARTLOG
      systemctl restart $n >/dev/null 2>&1
     done
   fi
 fi
}

#循环检查其它服务，如果异常重启之，跳过app和ctasd_out和kk_dpsam服务
check_other(){
Check_OS
RESULT=$?
if [ ${RESULT} -eq 0 ]
 then
   for servicename in $(chkconfig --list | grep "kk_" | awk -F" " '{print $1}')
   do
    for skip in kk_app kk_ctasd_out kk_dspam
    do
     if [ "$servicename" = "$skip" ]; then
#     echo "$CURRDATE skip $skip" >>$RESTARTLOG
     continue 2
     fi
    done
    /etc/init.d/$servicename status >/dev/null 2>&1
    RESULT=$?
    if [ ${RESULT} -ne 0 ]; then
    echo "$CURRDATE onlyrestart $servicename " >>$RESTARTLOG
    /etc/init.d/$servicename restart >/dev/null 2>&1
    fi
   done
 else
   for servicename in $(systemctl list-unit-files|grep "kk_" | awk -F" " '{print $1}')
   do
    for skip in kk_app.service kk_ctasd_out.service kk_dspam.service
    do
     if [ "$servicename" = "$skip" ]; then
#     echo "$CURRDATE skip $skip" >>$RESTARTLOG
     continue 2
     fi
    done
    systemctl status $servicename >/dev/null 2>&1
    RESULT=$?
    if [ ${RESULT} -ne 0 ]; then
    echo "$CURRDATE onlyrestart $servicename" >>$RESTARTLOG
    systemctl restart $servicename >/dev/null 2>&1
    fi
   done
 fi
}

check_app
check_other


