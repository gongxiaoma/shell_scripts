#!/bin/sh
if [ -e /usr/local/k-k/app/run/imapmail.pid ]
then
echo "running"
else
echo "not"
/usr/local/k-k/app/exec/imapmail --host 121.9.226.91 /usr/local/k-k/user
fi
