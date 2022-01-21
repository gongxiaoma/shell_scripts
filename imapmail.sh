#! /bin/bash
cat user | while read LINE
do
 yip=$(echo $LINE |awk  '{print $1}')
 yacc=$(echo $LINE |awk  '{print $2}')
 ypasswd=$(echo $LINE |awk  '{print $3}')
 dip=$(echo $LINE |awk  '{print $4}')
 dacc=$(echo $LINE |awk  '{print $5}')
 dpasswd=$(echo $LINE |awk  '{print $6}')
 /usr/bin/imapsync --host1 $yip --user1 $yacc --password1 "$ypasswd" --host2 $dip --user2 $dacc --password2 "$dpasswd"
done


