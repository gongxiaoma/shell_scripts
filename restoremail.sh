#!/bin/sh
MAILDIR=/maildata/mailbox/e-lead.cn/0
OLDDIR=/home/mailbox
NEWDIR=/maildata/mailbox

echo "" >/root/lostmailid
echo "" >/root/lostmailidok

for mailid in `cat /usr/local/k-k/log/app/postman.log.2018-03-06 | awk -F" " '{print $4}' | grep -v "^program" | egrep -v "^[0-9]" | sed "s/\[//g" | sed "s/\]//g" | grep -v "e-lead.cn$" | awk -F"-" '{print $1}'| uniq`
do
find $MAILDIR -name "*$mailid*" >>/root/lostmailid
done

cat /root/lostmailid | awk -F"/mailbox" '{print $2}' >>/root/lostmailidok

for line in `cat lostmailidok`
do
/usr/bin/expect<<EOF
spawn rsync -avz --progress "-e ssh -p 8787" $NEWDIR$line root@222.111.88.10:$OLDDIR$line
expect {
"yes/no" { send "yes\r"}
"*password:" { send "123456\r" }
}
expect eof
EOF
done
