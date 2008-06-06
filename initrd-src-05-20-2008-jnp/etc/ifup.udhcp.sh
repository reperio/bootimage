#!/bin/ash

[ -z "$1" ] && echo "Error: should be called from udhcpc" && exit 1

RESOLV_CONF="/etc/resolv.conf"
[ -n "$broadcast" ] && BROADCAST="broadcast $broadcast"
[ -n "$subnet" ] && NETMASK="netmask $subnet"

case "$1" in
	deconfig)
		/sbin/ifconfig $interface 0.0.0.0
		;;

	renew|bound)
		/sbin/ifconfig $interface $ip $BROADCAST $NETMASK

		if [ -n "$router" ] ; then
			while /sbin/route del default gw 0.0.0.0 dev $interface ; do
				:
			done

			for i in $router ; do
				/sbin/route add default gw $i dev $interface
			done
		fi

		echo -n > $RESOLV_CONF
		[ -n "$domain" ] && echo search $domain >> $RESOLV_CONF
		for i in $dns ; do
			echo adding dns $i
			echo nameserver $i >> $RESOLV_CONF
		done
		;;
esac

echo "NET_INTERFACE=$interface" 	> /tmp/network.dhcp
echo "NET_IPADDR=$ip" 			>> /tmp/network.dhcp
echo "NET_SUBNET=$subnet" 		>> /tmp/network.dhcp
echo "NET_BROADCAST=$broadcast" 	>> /tmp/network.dhcp
echo "NET_ROUTER=$router" 		>> /tmp/network.dhcp

MAC=`/sbin/ifconfig $interface | grep HWaddr | cut -d ' ' -f 11 | tr [A-H] [a-h]`
echo "NET_MACADDR=$MAC" 		>> /tmp/network.dhcp


exit 0
