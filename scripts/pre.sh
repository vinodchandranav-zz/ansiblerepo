#!/bin/ksh
#
# NAME: RHEL&SuSe-Linux-OS-Pre_Reboot_Health_Check.ksh
# PURPOSE: To collect pre-reboot outputs from RHEL servers
# AUTHOR(s): Shiju P <shiju.p@capgemini.com>
# DATE WRITTEN: 30 Jul 2014
# MODIFICATION HISTORY: None
#

PATH=$PATH:/usr/bin:/usr/sbin:/bin:/sbin:/usr/contrib/bin:/usr/local/bin
export PATH

# Declaring the variables
OS="`uname`"
date=`date +%d%m%y`
PRE_DIR=/var/tmp/preboot_`uname -n`
HOSTNAME=`uname -n`
MAIL=/bin/mail
BASEDIR=/var/tmp
DIR=${HOSTNAME}_${date}

#return codes
cRetSuccess=0
DiagnosedFlag=0

function DoExit
{
    echo "\""

    if [ $DiagnosedFlag -ne 0 ]
    then
        echo "Sanity diagnose"
    else
        echo "Sanity success"
    fi

    exit $cRetSuccess
}

function DisplayHeader
{
    echo "Sanity script stdout"
    echo "WFAN=\""
}

PrintUsage()
{
    echo
    echo "PURPOSE: To collect pre-reboot outputs from RHEL servers"
    DiagnosedFlag=1
    DoExit
}

DisplayHeader

if [ "$OS" != "Linux" ]
then
    echo "Script will work only on RHEL"
    echo
    DoExit
fi

while getopts e:s:h opt
do
    case $opt in
        e)  EMAIL="$OPTARG"
        ;;
        s)  SOURCE="$OPTARG"
        ;;
        h)  PrintUsage
        ;;
        *)  PrintUsage
        ;;
        ?)  PrintUsage
        ;;
    esac
done

#Checking Preboot Directory exist
if [ -d $PRE_DIR ]
then
    rm -rf $PRE_DIR
fi
mkdir -p $PRE_DIR
cd $PRE_DIR

echo -e "Computer CPU Information:" > cpuinfo
cat /proc/cpuinfo | grep processor >> cpuinfo

echo -e "Computer Memory Information:" > memoryinfo
rtotalram="$(free -mto | grep Total: | awk '{ print $2 " MB" }')"
echo -e "Total Ram: $rtotalram" >> memoryinfo

echo -e "Network Intereface details:" > ipaddrinfo
/sbin/ifconfig | grep "inet addr" >> ipaddrinfo

/sbin/ifconfig | grep "HWaddr" > hwaddrinfo

echo -e "Routing Table:" > routingtable
/bin/netstat -nr | wc -l >> routingtable

echo -e "Kernel Interface table:" > kerneliftable
/bin/netstat -in | wc -l >> kerneliftable

echo -e "File System (Mount):" > mountinfo
#cat /proc/mounts >> mountinfo
mount >> mountinfo

#Taking Configuration File Backup and Snapshots

# Creating Backup directory

echo -e "Creating backup directory..."

if [ -d ${BASEDIR}/${DIR} ]
then
    echo -e "Backup directory was created today. Removing for fresh backup..."
    rm -rf ${BASEDIR}/${DIR}
fi
mkdir ${BASEDIR}/${DIR}
cd ${BASEDIR}/${DIR}

sleep 5

echo -e "Gathering LVM data..."

if [ -f /sbin/vgdisplay ]
then
    /sbin/vgdisplay -vv > vginfo_v.$date 2>&1
else
    /usr/sbin/vgdisplay -vv > vginfo_v.$date 2>&1
fi

/usr/sbin/lvs > lvinfo.$date 2>&1
/usr/sbin/pvs > pvinfo.$date 2>&1
/usr/sbin/vgs > vginfo.$date 2>&1

/usr/sbin/lvdisplay > lvdisplayinfo.$date 2>&1
/usr/sbin/pvdisplay > pvdisplayinfo.$date 2>&1
/usr/sbin/vgdisplay > vgdisplayinfo.$date 2>&1

#For Physical Server
#echo -e "Multipath and HBA  Information..."

#multipath -ll > multipath.$date
#systool -c fc_host -v > systool.$date
#/opt/hp/hp_fibreutils/adapter_info > adapter_info.$date

#Gathering important System data
echo -e "Gathering important system data..."
cat /etc/redhat-release > OS-version.$date
cat /proc/cpuinfo | grep 'model name' | awk -F\: '{print $2}' > cpu-model-name.$date
cat /proc/cpuinfo | grep MHz | awk -F\: '{print $2}' > cpu-speed.$date
cat /proc/loadavg > loadavg.$date

#Collecting memory statistics.
/usr/bin/free -m > memoryinfo.$date
/usr/bin/free -lt -s $s -c $c > freelt.$date&
cat /proc/meminfo > meminfo.$date

#Collecting Swap information
swapon -s > swap_status.$date

#Collecting configuration files
echo -e "Collecting important system configuration files..."
cp -p /etc/hosts hosts.$date
cp -p /etc/resolv.conf resolv.conf.$date
cp -p /etc/fstab fstab.$date
cp -p /etc/grub.conf grub.conf.$date
cp -p /etc/xinetd.conf xinetd.conf.$date
cp -p /etc/syslog.conf 2>&1 syslog.conf.$date
cp -p /etc/bashrc bashrc.$date
cp -p /etc/csh.cshrc csh.cshrc.$date
cp -p /etc/csh.login csh.login.$date
#cp -p /etc/ftpusers ftpusers.$date
cp -p /etc/group group.$date
cp -p /etc/host.conf host.conf.$date
cp -p /etc/inittab inittab.$date
cp -p /etc/login.defs login.defs.$date
cp -p /etc/profile profile.$date
cp -p /etc/services services.$date
cp -p /etc/protocols protocols.$date
cp -p /etc/rc.local rc.local.$date
cp -p /etc/securetty securetty.$date
cp -p /etc/shells shells.$date
mkdir -p modprobe.d.$date
cp -p /etc/modprobe.d/* modprobe.d.$date
cp -p /etc/lvm/lvm.conf lvmconf.$date

if [ -f /etc/sudoers ]
then
    cp -p /etc/sudoers sudoers.$date
fi

if [ -f /etc/auto.master ]
then
    cp -p /etc/auto.master auto.master.$date
else
    echo -e "/etc/auto.master does not exist."
    sleep 2
fi

if [ -f /etc/auto.misc ]
then
    cp -p /etc/auto.misc auto.misc.$date
else
    echo -e "/etc/auto.misc does not exist."
    sleep 2
fi

if [ -f /etc/auto.net ]
then
    cp -p /etc/auto.net auto.net.$date
else
    echo -e "/etc/auto.net does not exist."
    sleep 2
fi

sleep 2

cp -p /etc/security/limits.conf limits.conf.$date

# For the ntp confs
echo -e "Gathering ntpd data..."
cp -p /etc/ntp.conf ntp.conf.$date
cp -p /etc/ntp/step-tickers step-tickers.$date
/usr/sbin/ntpq -p > ntp-query-status.$date
#Collecting Timezone data
/bin/date '+%Z' > timezone.$date
echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++" >> timezone.$date
/usr/sbin/zdump -v /etc/localtime >> timezone.$date

sleep 2

# Gathering the system/host details
echo -e "Gathering the system/host details..."
/bin/uname -r > kernelversion.$date
/bin/uname -a > uname-data.$date
hostname > hostname.$date

sleep 2

# Backing up the users data
echo -e "Backing up user login data ..."
cp -p /etc/passwd passwd.$date
cp -p /etc/shadow shadow.$date

sleep 2

# Backing up the system informations
echo -e "Backing up important networking informations...."
/bin/dmesg > dmesg.$date
/sbin/ifconfig -a > network-interfaces.$date
cat /etc/sysconfig/network-scripts/ifcfg* > ifcfg-details.$date
cat /etc/sysconfig/network > sysconfig-network-data.$date
/bin/netstat -rn > route.$date
/bin/netstat -in > netstat_in.$date
/usr/sbin/dmidecode > dmidecode.$date

sleep 2

# Taking the snapshot of current file system details
echo -e "Taking the snapshot of current file system details...."
/bin/mount -v > mountdata.$date
cp -p /etc/mtab mtab.$date
/bin/df -hT > df.$date
cat /proc/partitions > proc-partitions.$date

# Colecting the logs data
echo -e "Collecting logs....."
cp -p /var/log/boot.log boot.log.$date
/usr/bin/tail -500 /var/log/messages > messages.$date
/usr/bin/tail -500 /var/log/secure > secure.$date

sleep 2

# Taking snapshot of the installed packages and Services
echo -e "Taking snapshot of the installed packages and Services...."
/bin/rpm -qa --queryformat "%-32{NAME}\t%10{SIZE}\t%10{VERSION}\t%10{DISTRIBUTION}\n" > installed-rpm-list.txt-$date
/sbin/chkconfig --list 2>&1 > chkconfig.$date
service --status-all 2>&1 > service_status.$date

sleep 2

# Getting Gathering important data on open files/open ports/open processes
echo -e "Gathering important data on open files/ports/processes. This may take some time...."
/bin/netstat -an > openports.$date
#/usr/bin/top -n -2 > top-processes-before-reboot.$date
/bin/ps -aef > processes.$date
/usr/sbin/lsof > openfiles.$date 2>&1

cd ${BASEDIR}
tar zcf ${DIR}.tar.gz  ./${DIR}

if [ -f ${BASEDIR}/${DIR}.tar.gz ]
then

echo "========================================================================================================="
echo "The server sanity and configuration files backup is stored in this location path ${BASEDIR}/${DIR}.tar.gz"
echo "========================================================================================================="
else
    DiagnosedFlag=1

    echo "tar failed."

fi

DoExit
