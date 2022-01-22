#!/bin/bash
FILENAME=`date +%Y%m%d`
cd /usr/local/k-k/log
tar zcvf /home/backup/$FILENAME.tgz app/
