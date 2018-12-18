#!/bin/bash
#this script will return a CSV file containing the server,user,cronjob
##
#this is set to be able to use filters on wildcards
shopt -s extglob
#here we store the hostname since we only need to declare this once
HOST=$(hostname|cut -d"." -f1)
printf   $HOST","
for RESOLVE in `cat /etc/resolv.conf|sed /^#/d`
do
printf  $RESOLVE
done
printf ","
for KERB in `cat /etc/krb5.conf|sed /^#/d|egrep -i "kdc|admin_server"|egrep -v "log|dns"`
do
printf   $KERB
done
printf ","
for SMB in `cat /etc/samba/smb.conf|sed /^#/d|grep -v ";"|egrep -i "password server"`
do
printf  $SMB
done
#and finally here we print the actual command and since we desire a new line echo is used here instead of printf
echo "$line"
