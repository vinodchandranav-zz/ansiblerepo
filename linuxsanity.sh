echo " =============Uptime==================" > /var/sanity.txt 
uptime >> /var/sanity.txt
echo "==============uname=====================" >> /var/sanity.txt
uname -a >> /var/sanity.txt
echo "======================ifconfig============" >> /var/sanity.txt
/sbin/ifconfig -a >> /var/sanity.txt
echo "===================/etc/fstab========" >> /var/sanity.txt
cat /etc/fstab >> /var/sanity.txt
echo "=====================/etc/grub.conf====" >> /var/sanity.txt
cat /etc/grub.conf >> /var/sanity.txt
echo "==================chkconfig========" >> /var/sanity.txt
/sbin/chkconfig --list >> /var/sanity.txt
echo "===================netstat========" >> /var/sanity.txt
netstat -nr >> /var/sanity.txt
echo "================df===============" >> /var/sanity.txt
df -h >> /var/sanity.txt
echo "=============cpu info================" >> /var/sanity.txt
cat /proc/cpuinfo >> /var/sanity.txt
