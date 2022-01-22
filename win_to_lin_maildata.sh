#! /bin/bash
#定义路径变量
MAILDOMAIN=domain.com
WINDIR=/windows/Users/$MAILDOMAIN
LINDIR=/usr/local/k-k/data/mailbox/$MAILDOMAIN/0
WINCAOGAO="Drafts.IMAP"
WINLAJI="Deleted Items.IMAP"
WINFA="Sent Items.IMAP"
WINZI="Inbox.IMAP"
DATADIR=/usr/local/k-k/data/mailbox

#循环读取帐号
ls -lh $WINDIR | awk -F " " '{ print $NF }' | sed 1d | while read LINE
do
 kkuser=$(echo $LINE |awk  '{print $1}')
 if [ ! -d "$LINDIR/$kkuser" ]; then
  mkdir -p $LINDIR/$kkuser/cur
  mkdir -p $LINDIR/$kkuser/.Drafts/cur
  mkdir -p $LINDIR/$kkuser/.Trash/cur
  mkdir -p $LINDIR/$kkuser/.Sent/cur
 fi
 echo -e
 echo -e
 echo "#####################################开始迁移$kkuser用户数据##############################################"
 echo "复制收件箱"
 rsync -avzrtopgL  --progress $WINDIR/$kkuser/*.msg $LINDIR/$kkuser/cur/
 echo -e
 echo "复制草稿箱"
 rsync -avzrtopgL  --progress $WINDIR/$kkuser/"${WINCAOGAO}"/*.msg $LINDIR/$kkuser/.Drafts/cur/
 echo -e
 echo "复制垃圾箱"
 rsync -avzrtopgL  --progress $WINDIR/$kkuser/"${WINLAJI}"/*.msg $LINDIR/$kkuser/.Trash/cur/
 echo -e
 echo "复制发件箱"
 rsync -avzrtopgL  --progress $WINDIR/$kkuser/"${WINFA}"/*.msg $LINDIR/$kkuser/.Sent/cur/

   echo -e
   echo -e
   echo "复制用户自建文件夹数据"
   ls -l $WINDIR/$kkuser |grep "IMAP" |grep -v "Sent Items" | grep -v "Drafts" | grep -v "Deleted Items" | grep -v "Inbox" |awk '{printf ".INBOX.%s\n", $9}' | sed s/\.IMAP//g | while read DIY
   do
   mkdir -p $LINDIR/$kkuser/$DIY
   WINDIY=$(echo $DIY |sed 's/.INBOX.//g' |sed 's/$/&.IMAP/g')
   rsync -avzrtopgL  --progress $WINDIR/$kkuser/$WINDIY/*.msg $LINDIR/$kkuser/$DIY/cur/
   done
   
   echo -e
   echo -e
   echo "复制子文件夹数据"
   ls -l $WINDIR/$kkuser/"${WINZI}" |grep "IMAP" |grep -v "Sent Items" | grep -v "Drafts" | grep -v "Deleted Items" | grep -v "Inbox" |awk '{printf ".INBOX.%s\n", $9}' | sed s/\.IMAP//g | while read ZIY
   do
   mkdir -p $LINDIR/$kkuser/$ZIY
   WINZIY=$(echo $ZIY |sed 's/.INBOX.//g' |sed 's/$/&.IMAP/g')
   rsync -avzrtopgL  --progress $WINDIR/$kkuser/"${WINZI}"/$WINZIY/*.msg $LINDIR/$kkuser/$ZIY/cur/
   done
   echo "####################################迁移完成$kkuser用户数据#############################################"
 done

echo -e
echo -e
echo "******迁移完成******"
echo "设置权限完成"
chown -hR kk.kk $DATADIR
chmod -R 755 $DATADIR


