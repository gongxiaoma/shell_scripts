#! /bin/bash
ls -lh 0/ | awk -F " " '{ print $NF }' | sed '1d' >./user
cat user | while read LINE
do
 acc=$(echo $LINE |awk  '{print $1}')
 mkdir -p 0/$acc/".INBOX.&W1hoY5CuTvY-"
 mkdir -p 0/$acc/".INBOX.&W1hoY5CuTvY-/cur"
 chown -hR kk.kk 0/$acc/".INBOX.&W1hoY5CuTvY-"
 chmod -R 755 0/$acc/".INBOX.&W1hoY5CuTvY-"
 mv -v 0/$acc/cur/* 0/$acc/".INBOX.&W1hoY5CuTvY-"/cur/ 
 mv -v 0/$acc/new/* 0/$acc/".INBOX.&W1hoY5CuTvY-"/cur/
done

