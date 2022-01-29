#!/bin/bash

# check permission
if `apt-get update > /dev/null 2> /dev/null`
	then
		echo ''
	else
		echo 'Permission denied'
		exit 1
fi

cat SETUP_VARIABLES
echo -n 'Confirm (y/n): '
read CONFIRMATION

if [[ $CONFIRMATION != 'y' && $CONFIRMATION != 'Y' ]]
	then
		exit 1
fi

apt-get install -y iptables-persistent
systemctl enable netfilter-persistent.service

#
SERVER_IP=`cat SETUP_VARIABLES | grep -oP '(?<=SERVER_IP\=).*(?=$)'`
#

# check permission
if `iptables-save > /etc/iptables/rules.v4 > /dev/null 2> /dev/null`
	then
		echo ''
	else
		echo 'Permission denied'
		exit 1
fi

# prepare
apt-get install -y unbound resolvconf

systemctl stop systemd-resolved
systemctl disable systemd-resolved

systemctl enable resolvconf
systemctl start resolvconf

# prepare config
echo 'server:' > /etc/unbound/unbound.conf.d/unbound.conf
echo '    access-control: '$SERVER_IP'/32 allow' >> /etc/unbound/unbound.conf.d/unbound.conf
cat unbound.conf >> /etc/unbound/unbound.conf.d/unbound.conf

# restart
/etc/init.d/unbound restart

# redirecting service
echo '#!/bin/bash' > /etc/unbound/redirecting.sh
cat SETUP_VARIABLES | grep "SERVER_IP=" >> /etc/unbound/redirecting.sh
cat redirecting.sh >> /etc/unbound/redirecting.sh
chmod +x /etc/unbound/redirecting.sh
cp unbound-redirecting.service /etc/systemd/system/unbound-redirecting.service
chmod +x /etc/systemd/system/unbound-redirecting.service
systemctl enable unbound-redirecting

# apply redirecting
bash /etc/unbound/redirecting.sh
