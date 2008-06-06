#!/bin/ash

. /etc/library.sh

NET_MODULE_PATH="/lib/modules/`uname -r`/kernel/drivers/net"

dhcp_on_interface() {
	INTERFACE=${1}


	# this is a stop gap for my laptop
	if [ "${INTERFACE}" = "ath0" ]
	then
		return 1
	fi

	msg -n "Trying DHCP on ${i} interface"

	/sbin/udhcpc -i ${INTERFACE} -n -s /etc/ifup.udhcp.sh \
		-p /tmp/dhcp.${INTERFACE}.pid >> /tmp/stdout.log 2>> /tmp/stderr.log

	if [ "$?" = 0 ]
	then
		. /tmp/network.dhcp
		ok_msg
		return 0
	else
		fail_msg
		return 1
	fi
}

header "Loading network card modules"

for i in `find ${NET_MODULE_PATH} -name \*.ko`
do
	load_module "${i}"
done

header "Finding ethernet devices"

NET_DEVICES=`/sbin/ifconfig -a | grep "^[a-z]" | cut -d" " -f1`
NET_DEVICE_COUNT=0
NET_DEVICE=""

for i in ${NET_DEVICES}
do

	# we want to skip the loopback interfaces since they don't really count
	if [ "${i}" = "lo" ]
	then
		continue
	fi

	NET_DEVICE_COUNT=`expr ${NET_DEVICE_COUNT} + 1`

	msg -n "Checking link status for ${i}"
	/bin/mii-diag -s ${i} >> /tmp/stdout.log 2>> /tmp/stderr.log

	if [ "$?" != "0" ];
	then
		fail_msg
	else
		ok_msg
		dhcp_on_interface ${i}
		if [ "$?" = "0" ]
		then
			NET_DEVICE="${i}"
		fi
	fi
done

if [ "${NET_DEVICE_COUNT}" = "0" ];
then
	fatal_error "No network devices found on your system"
fi

if [ "${NET_DEVICE}" = "" ];
then
	msg ""
	msg "Unable to find interface with link, manually trying each interface"
	for i in ${NET_DEVICES}
	do
		if [ "${i}" = "lo" ]
		then
			continue
		fi

		dhcp_on_interface ${i}
		if [ "$?" = "0" ]
		then
			NET_DEVICE="${i}"
			break
		fi
	done
fi

if [ "${NET_DEVICE}" = "" ];
then
	fatal_error "DHCP server did not respond on any network interface"
fi

msg -n "Setting hostname to be HW address  "
HOST=`echo ${NET_MACADDR} | sed 's/://g'`
msg -n " ${NET_MACADDR}"
hostname ${HOST} >> /tmp/stdout.log 2> /tmp/stderr.log
if [ "$?" = 0 ]
then
	ok_msg
else
	fail_msg
fi

header "Network Settings"

msg "Network interface:  ${NET_INTERFACE}"
msg "       IP address:  ${NET_IPADDR}"
msg "      Subnet mask:  ${NET_SUBNET}"
msg "          Gateway:  ${NET_ROUTER}"
msg " Hardware address:  ${NET_MACADDR}"

breakin_start

exit 0
