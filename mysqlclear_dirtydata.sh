#!/bin/sh
kkmysqlpass=$(cat /usr/local/k-k/config/custom.conf | grep -w "pass" | awk -F" " '{print $NF}')
/usr/local/k-k/service/mysql/bin/mysql -u kk -p$kkmysqlpass kk -e "select * from core_mailbox where mailbox_id not in (select mailbox_id from co_user);" >/root/chaji.txt
cat /root/test.txt | awk -F" " '{print $1"\t"$2}' | sed 1d >/root/chaji_id.txt
cat /root/chaji_id.txt | while read LINE
do
 mailbox_id=$(echo $LINE |awk  '{print $1}')
 domain_id=$(echo $LINE |awk  '{print $2}')
 /usr/local/k-k/service/mysql/bin/mysql -u kk -p$kkmysqlpass kk -e "insert into co_user(mailbox_id,domain_id,realname,engname,oabshow,showorder,eenumber,gender,birthday,homepage,tel_mobile,tel_home,tel_work,tel_work_ext,tel_group,im_qq,im_msn,addr_country,addr_state,addr_city,addr_address,addr_zip,remark,last_session,last_login,openid,unionid,wx_id) values('$mailbox_id','$domain_id','testdel2','NULL','1','0','NULL','male','0000-00-00','NULL','NULL','NULL','NULL','NULL','NULL','NULL','NULL','NULL','NULL','NULL','NULL','NULL','NULL','NULL','NULL','0','0','0');"
done

