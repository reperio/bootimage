#!/bin/ash

. /etc/library.sh

# -----------------------------------------------------------------------
# load the output file created by the breakin program
# -----------------------------------------------------------------------
if [ -e /var/run/breakin.dat ]
then
	. /var/run/breakin.dat
fi

# FIXME:

NET_MODULE_PATH="/lib/modules/`uname -r`/kernel/drivers/net"
SCSI_MODULE_PATH="/lib/modules/`uname -r`/kernel/drivers/scsi"
LIBATA_MODULE_PATH="/lib/modules/`uname -r`/kernel/drivers/ata"
MD_MODULE_PATH="/lib/modules/`uname -r`/kernel/drivers/md"
FUSIONMPT_MODULE_PATH="/lib/modules/`uname -r`/kernel/drivers/message/fusion"
MODULE_PREFIX="/lib/modules/`uname -r`/kernel/drivers"
SENSOR_ENABLE=0

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

if [ "${spantree}" != "" ]
then
	msg "Sleeping for ${spantree} seconds for spanning tree"
	sleep ${spantree}
fi


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

#msg -n "Setting hostname to be HW address  "
#HOST=`echo ${NET_MACADDR} | sed 's/://g'`
#msg -n " ${NET_MACADDR}"
#hostname ${HOST} >> /tmp/stdout.log 2> /tmp/stderr.log
#if [ "$?" = 0 ]
#then
	#ok_msg
#else
	#fail_msg
#fi

for i in /lib/modules/`uname -r`/kernel/drivers/edac/*
do
	MOD_NAME=`basename ${i} | cut -d"." -f1`
	modprobe_module ${MOD_NAME}
done

for i in /lib/modules/`uname -r`/kernel/drivers/i2c/busses/*
do
	MOD_NAME=`basename ${i} | cut -d"." -f1`
	modprobe_module ${MOD_NAME}
done

for i in /lib/modules/`uname -r`/kernel/drivers/hwmon/*
do
	MOD_NAME=`basename ${i} | cut -d"." -f1`
	modprobe_module ${MOD_NAME}
done

# XXX: this may cause lockups, if so we need a better way
header "Loading all SCSI/SATA disk modules"

for i in `find ${SCSI_MODULE_PATH} ${LIBATA_MODULE_PATH} ${FUSIONMPT_MODULE_PATH} ${MD_MODULE_PATH} -name \*.ko`
do
	MOD_NAME=`basename ${i} | cut -d"." -f1`
	modprobe_module ${MOD_NAME}
done

header "Loading other modules"
for i in `cat /etc/modules_other.conf`
do
	modprobe_module ${i}	
done

msg "Waiting 10 seconds for block devices to settle."
sleep 10

# mount a logging device
. /etc/logdev.sh

. /etc/hardware_output.sh
