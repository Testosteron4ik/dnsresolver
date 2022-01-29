#!/bin/bash

#
SERVER_IP=`cat /etc/unbound/redirecting.sh | grep -oP '(?<=SERVER_IP\=).*(?=$)'`
#

# check permission
if `iptables-save > /etc/iptables/rules.v4 > /dev/null 2> /dev/null`
	then
		echo ''
	else
		echo 'Permission denied'
		exit 1
fi

# delete iptables rules
systemctl stop unbound-redirecting
systemctl disable unbound-redirecting
iptables -w 10 -t nat -D OUTPUT -m owner --uid-owner unbound -p udp --dport 53 -j RETURN
iptables -w 10 -t nat -D OUTPUT -m owner --uid-owner unbound -p tcp --dport 53 -j RETURN
iptables -w 10 -t filter -D FORWARD -p udp --dport 53 -j DROP
iptables -w 10 -t filter -D FORWARD -p tcp --dport 53 -j DROP
iptables -w 10 -t nat -D OUTPUT -s $SERVER_IP/32 -p udp --dport 53 -j DNAT --to 127.0.0.1:53
iptables -w 10 -t nat -D OUTPUT -s $SERVER_IP/32 -p tcp --dport 53 -j DNAT --to 127.0.0.1:53
iptables-save > /etc/iptables/rules.v4

# uninstall
/etc/init.d/unbound stop
systemctl stop resolvconf
systemctl disable resolvconf
apt-get remove --purge -y unbound resolvconf
rm -f /etc/unbound/unbound.conf.d/unbound.conf
rm -f /etc/unbound/redirecting.sh
rm -f /etc/systemd/system/unbound-redirecting.service
systemctl enable systemd-resolved
systemctl start systemd-resolved
