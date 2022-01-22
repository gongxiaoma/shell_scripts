#!/bin/sh
#author:gxm
#version:1.1

#安装samba相关包（samba-swat是https图形化界面）
yum -y install samba samba-client

#设置samba访问帐号和密码，gxm帐号要用useradd先添加,然后这个账号要对目录有权限
useradd gxm
echo -e "gxm\ngxm" | smbpasswd -s -a gxm

#编辑配置文件（如果security等于share，表示不需要帐号和密码）
mv /etc/samba/smb.conf /etc/samba/smb.conf.bak
touch /etc/samba/smb.conf
cat > /etc/samba/smb.conf  << EOF
[global]
workgroup = WORKGROUP
server string = Samba Server Version %v
netbios name = SambaServer
log file = /var/log/samba/%m.log
max log size = 50
security = user
[gxm]
path = /
writeable = yes
valid user = root
browseable = yes
EOF

#关闭selinux
setenforce 0
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config

#配置防火墙
iptables -I INPUT -p tcp --dport 137 -j ACCEPT
iptables -I INPUT -p tcp --dport 138 -j ACCEPT
iptables -I INPUT -p tcp --dport 139 -j ACCEPT
iptables -I INPUT -p tcp --dport 445 -j ACCEPT
/etc/init.d/iptables save
/etc/init.d/iptables reload

#重启smb服务并设置成开机启动
/etc/init.d/smb restart
chkconfig smb on

#可以查看smb端口、检测smb.conf配置文件、linux客户端登录访问共享文件
#netstat -tplnu | grep smb
#testparm
#smbclient //192.168.1.103/gxm -U root
