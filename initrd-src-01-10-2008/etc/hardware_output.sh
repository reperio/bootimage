#!/bin/ash

. /etc/library.sh


disk_list() {

	DISK_COUNT=0

	for i in `ls -1 /proc/ide/hd* | grep "/proc/ide/hd[a-z]$" 2>> /tmp/stderr.log`
	do
		dev=`basename $i`
		size=`disk_size $dev`
		model=`cat /proc/ide/$dev/model | head -1`
		echo "DISK_${DISK_COUNT}_DEV=\"$dev\""
		echo "DISK_${DISK_COUNT}_SIZE=\"$size\""
		echo "DISK_${DISK_COUNT}_MODEL=\"$model\""
		DISK_COUNT=`expr ${DISK_COUNT} + 1`
	done

	for i in `ls -1 /dev/sd* | grep "/dev/sd[a-z]$`
	do
		dev=`basename $i`
		exists=`cat /proc/partitions | awk '{print  $4}' | grep $dev`
		if [ "${exists}" != "" ]
		then
			size=`disk_size $dev`
			model=`cat /sys/block/$dev/device/model`
			vendor=`cat /sys/block/$dev/device/vendor`	
			scsi="${scsi} ### $dev:$size:$vendor $model"

			echo "DISK_${DISK_COUNT}_DEV=\"$dev\""
			echo "DISK_${DISK_COUNT}_SIZE=\"$size\""
			echo "DISK_${DISK_COUNT}_MODEL=\"$vendor $model\""
			DISK_COUNT=`expr ${DISK_COUNT} + 1`
		fi
	done
	echo "DISK_COUNT=\"${DISK_COUNT}\""
}

disk_size() {
	dev=$1
	
	size=`cat /proc/partitions | awk '{ print $3, $4 }' | grep "${dev}$" | awk '{print $1}'`
	echo $size
}

network_list() {

	NIC_COUNT=0

	for dev in `ls -1 /sys/class/net`
	do
		driver=""
		pci_dev=""
		dev_vend=""
		dev_dev=""

		hwaddr=`cat /sys/class/net/${dev}/address`

		if [ "${dev}" = "lo" ]
		then
		    continue
	    	fi
		echo "NIC_${NIC_COUNT}_DEV=\"${dev}\""
		echo "NIC_${NIC_COUNT}_HWADDR=\"${hwaddr}\""

		if [ -e /sys/class/net/${dev}/driver ]
		then
			driverlnk=`readlink /sys/class/net/${dev}/driver`
			driver=`basename $driverlnk`
		fi

		if [ -e /sys/class/net/${dev}/device ]
		then
			dev_vend=`cat /sys/class/net/${dev}/device/vendor`
			dev_dev=`cat /sys/class/net/${dev}/device/device`
		fi
		#driver=`basename ${driverlnk}`
		echo "NIC_${NIC_COUNT}_DRIVER=\"${driver}\""
		echo "NIC_${NIC_COUNT}_PCIDEV=\"${dev_dev}\""
		echo "NIC_${NIC_COUNT}_PCIVENDOR=\"${dev_vend}\""

		NIC_COUNT=`expr ${NIC_COUNT} + 1`
	done
	echo "NIC_COUNT=\"${NIC_COUNT}\""

}

pci_list() {
	PCI_COUNT=0
	for i in /sys/bus/pci/devices/*
	do
		busid=`basename $i`
		device=`cat ${i}/device`
		vendor=`cat ${i}/vendor`
		irq=`cat ${i}/irq`
		class=`cat ${i}/class`

		echo "PCI_${PCI_COUNT}_BUSID=\"$busid\""
		echo "PCI_${PCI_COUNT}_DEVICE=\"$device\""
		echo "PCI_${PCI_COUNT}_VENDOR=\"$vendor\""
		echo "PCI_${PCI_COUNT}_CLASS=\"$class\""
		echo "PCI_${PCI_COUNT}_IRQ=\"$irq\""

		PCI_COUNT=`expr ${PCI_COUNT} + 1`
	done

	echo "PCI_COUNT=\"${PCI_COUNT}\""
}

/usr/local/bin/dmidecode	> /tmp/hardware.dat
disk_list 		>> /tmp/hardware.dat
network_list 	>> /tmp/hardware.dat
pci_list 		>> /tmp/hardware.dat

