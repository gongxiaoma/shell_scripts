#/bin/bash
#author gxm@comingchina.com
#data 2018-06-28
#version 1.0
POSTMAN="/root/postman.log"
STATISTICAL="/tmp/statistical.log"
MAILID=`egrep -o '[[^0-9A-Za-z-]{22}]' $POSTMAN | sed 's/\[//g' |sed 's/\]//g' | sort | uniq`

echo "">$STATISTICAL

for i in $MAILID;
do
    MAILSIZE=`grep $i $POSTMAN | grep "size:" | awk -F"size:" '{print $NF}'`
    RECEIPENT=`grep $i $POSTMAN | grep "save file to" |wc -l`
    SUM_MAILSIZE=`expr $MAILSIZE \* $RECEIPENT`
    SUM_MAILSIZE_M=`expr $SUM_MAILSIZE \/ 1048576`
    echo "ID为" $i "的邮件收件人数量为" $RECEIPENT "总共产生容量为" $SUM_MAILSIZE_M "M" >>$STATISTICAL
done

echo "产生最大容量的邮件（TOP20）信息"
cat $STATISTICAL | sort -rn -k 6 | head -n 20

#cs的版本是awk数组，思路如awk '{ count[$4]++; if(NF==10){sizea[$10]++} }END{len=asorti(count,newcount);asorti(sizea,newsizea);for(i=1;i<=len;i++){print i,newcount[i],count[newcount[i]],newsizea[i],count[newcount[i]]*newsizea[i]} }' postman.log | sort -rn -k 5 | head -n 20
#当前这个脚本运行所花时间要2分钟30秒，python脚本3-6秒左右
