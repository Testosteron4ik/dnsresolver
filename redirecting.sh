sysctl -w net.ipv4.conf.all.route_localnet=1

# allow unbound to send dns requests
if ! `iptables -w 10 -t nat -C OUTPUT -m owner --uid-owner unbound -p udp --dport 53 -j RETURN > /dev/null 2> /dev/null`
	then
		iptables -w 10 -t nat -A OUTPUT -m owner --uid-owner unbound -p udp --dport 53 -j RETURN
fi

if ! `iptables -w 10 -t nat -C OUTPUT -m owner --uid-owner unbound -p tcp --dport 53 -j RETURN > /dev/null 2> /dev/null`
	then
		iptables -w 10 -t nat -A OUTPUT -m owner --uid-owner unbound -p tcp --dport 53 -j RETURN
fi

# deny all forwarding dns requests
if ! `iptables -w 10 -t filter -C FORWARD -p udp --dport 53 -j DROP > /dev/null 2> /dev/null`
	then
		iptables -w 10 -t filter -I FORWARD 1 -p udp --dport 53 -j DROP
fi

if ! `iptables -w 10 -t filter -C FORWARD -p tcp --dport 53 -j DROP > /dev/null 2> /dev/null`
	then
		iptables -w 10 -t filter -I FORWARD 2 -p tcp --dport 53 -j DROP
fi

# redirect all output dns requests from WAN network adapter to local resolver
if ! `iptables -w 10 -t nat -C OUTPUT -s $SERVER_IP/32 -p udp --dport 53 -j DNAT --to 127.0.0.1:53 > /dev/null 2> /dev/null`
	then
		iptables -w 10 -t nat -A OUTPUT -s $SERVER_IP/32 -p udp --dport 53 -j DNAT --to 127.0.0.1:53
fi

if ! `iptables -w 10 -t nat -C OUTPUT -s $SERVER_IP/32 -p tcp --dport 53 -j DNAT --to 127.0.0.1:53 > /dev/null 2> /dev/null`
	then
		iptables -w 10 -t nat -A OUTPUT -s $SERVER_IP/32 -p tcp --dport 53 -j DNAT --to 127.0.0.1:53
fi

iptables-save > /etc/iptables/rules.v4
