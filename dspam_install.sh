#!/bin/bash
#Date 2017-10-14
#Author:GXM	
#Mail:gxm@comingchina.com
#Function:dsapm deploy
#Version:1.2
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
# 变量1区
DSPAM_DOWNLOAD="http://www.mailrelay.cn/static/dspam/dspam_full.gz"
SETUP_DOWNLOAD="http://www.comingchina.com/download/soft/other/update.tar.gz"
PARTITION_MAX_SIZE_B=$(df -P --block-size=1024 | sed '1d' | awk '{print $4,$NF}'| sort -rn | head -1 | awk '{print $1}')
PARTITION_MAX_SIZE_DIR=$(df -P --block-size=1024 | sed '1d' | awk '{print $4,$NF}'| sort -rn | head -1 | awk '{print $NF}')
DIY_SIZE="10971520"
#####################################################################
# 函数区
# 检测 wget 程序
check_wget_program()
{
    [ -e /usr/bin/wget ] && return 0
    echo "Error: 没有安装wget工具!"
    exit 2
}

# 检测 tar 程序
check_tar_program()
{
    [ -e /bin/tar ] && return 0
    echo "Error: 没有安装tar工具!"
    exit 2
}

# 检测 yum 程序
check_yum_program()
{
    [ -e /usr/bin/yum ] && return 0
    echo "Error: 没有安装yum工具!"
    exit 2
}

# 检测 gunzip 程序
check_gunzip_program()
{
    [ -e /bin/gunzip ] && return 0
    echo "Error: 没有安装gunzip工具!"
    exit 2
}

#####################################################################
# 执行区
echo
echo "############################################################"
echo "找出最大分区，并检查剩余容量是否足够"
echo $PARTITION_MAX_SIZE_DIR
if (("$PARTITION_MAX_SIZE_B" < "$DIY_SIZE")); then
      echo "硬盘容量不够，现在退出脚本"
      exit 2
fi

echo
echo "############################################################"
echo "安装wget包"
check_wget_program
yum -y install wget
RESULT=$?
if [ ${RESULT} -ne 0 ]; then
    echo "安装wget出错"
	exit 2
fi


echo
echo "############################################################"
echo "下载DSPAM安装程序"
check_wget_program
wget -O /tmp/update.tar.gz "${SETUP_DOWNLOAD}"
RESULT=$?
if [ ${RESULT} -ne 0 ]; then
    echo "下载出错"
	exit 2
fi


echo
echo "############################################################"
echo "下载DSPAM库"
check_wget_program
wget --no-check-certificate -O /tmp/dspam_full.gz "${DSPAM_DOWNLOAD}"
RESULT=$?
if [ ${RESULT} -ne 0 ]; then
    echo "下载出错"
	exit 2
fi


echo
echo "############################################################"
echo "解压DSPAM安装程序"
check_tar_program
tar -zxvf /tmp/update.tar.gz -C /usr/local/k-k/
RESULT=$?
if [ ${RESULT} -ne 0 ]; then
    echo "解压出错"
	exit 2
fi

echo
echo "############################################################"
echo "安装DSPAM程序"
sh /usr/local/k-k/update/update.sh
RESULT=$?
if [ ${RESULT} -ne 0 ]; then
    echo "安装出错"
#	exit 2
fi


echo
echo "############################################################"
echo "启动测试DSPAM"
/usr/local/k-k/app/engine/bin/python /usr/local/k-k/app/repo/confbuilder.pyc dspam
/etc/init.d/kk_dspam restart


echo
echo "############################################################"
echo "判断是否要更改pgsql配置文件"
if [[ "$PARTITION_MAX_SIZE_DIR" = "/" ]]; then
       echo "最大分区为根，pgsql配置文件不需要更改"  
      else
	   echo "最大分区为非根，更改pgsql配置文件指向新目录"
	   mkdir -p $PARTITION_MAX_SIZE_DIR/kkpgservice/pgsql-9.4/data/
       sed -i 's#PGDATA=/usr/local/k-k/service/pgsql-9.4/data/data#PGDATA='$PARTITION_MAX_SIZE_DIR'/kkpgservice/pgsql-9.4/data/data#' /etc/init.d/kk_postgresql
       sed -i 's#PGLOG=/usr/local/k-k/service/pgsql-9.4/data/pgstartup.log#PGLOG='$PARTITION_MAX_SIZE_DIR'/kkpgservice/pgsql-9.4/data/pgstartup.log#' /etc/init.d/kk_postgresql
	   sed -i 's#PGUPLOG=/usr/local/k-k/service/pgsql-9.4/data/pgupgrade.log#PGUPLOG='$PARTITION_MAX_SIZE_DIR'/kkpgservice/pgsql-9.4/data/pgupgrade.log#' /etc/init.d/kk_postgresql
       cp /usr/local/k-k/service/pgsql-9.4/data/data/ $PARTITION_MAX_SIZE_DIR/kkpgservice/pgsql-9.4/data/ -rf
       chown -R kk_postgres:kk_postgres $PARTITION_MAX_SIZE_DIR/kkpgservice/pgsql-9.4/
       /etc/init.d/kk_postgresql restart   
fi


#####################################################################
# 变量3区
CISHU=$(/usr/local/k-k/update/test_dspam.sh | grep -o "Innocent" | wc -l)
#####################################################################
#if (("$CISHU" >= 1)); then
#     echo "DSPAM程序测试正常"
#	 else
#	 echo "DSPAM程序测试不正常"
#	 exit 2
#fi


echo
echo "############################################################"
echo "解压DSPAM库"
check_gunzip_program
yum -y install gzip
if [[ "$PARTITION_MAX_SIZE_DIR" = "/" ]]; then
     echo "最大分区为根，解压在tmp目录下" 
     cd /tmp
	 gunzip -c /tmp/dspam_full.gz > /tmp/dspam_full.sql
	 RESULT=$?
      if [ ${RESULT} -ne 0 ]; then
       echo "解压DSPAM库出错"
	   exit 2
      fi
    else
	 echo "最大分区为非根，解压在指定目录下"
	 cd $PARTITION_MAX_SIZE_DIR/kkpgservice
	 gunzip -c /tmp/dspam_full.gz > $PARTITION_MAX_SIZE_DIR/kkpgservice/dspam_full.sql
	 RESULT=$?
      if [ ${RESULT} -ne 0 ]; then
       echo "解压DSPAM库出错"
	   exit 2
      fi
fi

echo
echo "############################################################"
echo "删除下载文件"
rm -f /tmp/update.tar.gz
rm -f /tmp/dspam_full.gz


echo
echo "############################################################"
echo "重命名导入DSPAM库"
if [[ "$PARTITION_MAX_SIZE_DIR" = "/" ]]; then
     echo "最大分区为根，重命名导入DSPAM库" 
     sh /usr/local/k-k/update/update_dspam.sh /tmp/dspam_full.sql
	 RESULT=$?
      if [ ${RESULT} -ne 0 ]; then
       echo "重命名导入DSPAM库出错"
	   exit 2
      fi
    else
	 echo "最大分区为非根，重命名导入DSPAM库"
	 sh /usr/local/k-k/update/update_dspam.sh $PARTITION_MAX_SIZE_DIR/kkpgservice/dspam_full.sql
	 RESULT=$?
      if [ ${RESULT} -ne 0 ]; then
       echo "重命名导入DSPAM库出错"
	   exit 2
      fi
fi


echo
echo "############################################################"
echo "测试DSPAM运行结果"
#####################################################################
# 变量4区
CISHU2=$(/usr/local/k-k/update/test_dspam.sh | grep -o "Spam" | wc -l)
#####################################################################
if (("$CISHU2" >= 1)); then
     echo "DSPAM运行正常"
	 else
	 echo "DSPAM运行不正常"
	 exit 2
fi

echo
echo "############################################################"
echo "删除dspam相关文件"
if [[ "$PARTITION_MAX_SIZE_DIR" = "/" ]]; then
     echo "最大分区为根，删除dspam相关文件" 
     rm -f /tmp/dspam_full.gz
	 rm -f /tmp/dspam_full.sql
    else
	 echo "最大分区为非根，删除dspam相关文件"
     rm -f $PARTITION_MAX_SIZE_DIR/kkpgservice/dspam_full.sql
fi
