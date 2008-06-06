#!/bin/ash

. /etc/library.sh
. /etc/cloner/include.sh


# TODO:
#
#  1. Finish software RAID setup
#

if [ "${_nomkfs}" = "" ]
then

	header "Partiting disks and formating filesystems"

	DELAY=15
	msg "Going to partition and format disks in ${DELAY} seconds, press [CTRL-C] to abort"
	msg -n "${ANSI_BLUE}"
	while [ "${DELAY}" != "0" ]
	do
		msg -n " ${ANSI_BLUE}${DELAY} ${ANSI_DONE} "
		sleep 1
		DELAY=`expr ${DELAY} - 1`
	done
	msg ""
	

	header "Partition the disk devices"
	
	for i in `ls -1 /cloner/setup/*.sfdisk`
	do
		DEVICE=`basename ${i}`
		DEVICE=`echo ${DEVICE} | sed 's/\..*//g'`
	
	
		msg -n "Partition device ${ANSI_BLUE}${DEVICE}${ANSI_DONE} "
	
		/usr/local/bin/sfdisk --force --no-reread -uM /dev/${DEVICE} < ${i} \
			>> /tmp/stdout.log 2>>/tmp/stderr.log
	
		if [ "$?" != "0" ];
		then
			fail_msg
			fatal_error "Failed to partition disk device ${DEVICE} check /tmp/stdout.log or /tmp/stderr.log for details"
		else
			ok_msg
		fi
	done
	
	for i in `ls -1 /cloner/setup/*.sec_fdisk 2> /dev/null`
	do
		DEVICE=`basename ${i}`
		DEVICE=`echo ${DEVICE} | sed 's/\..*//g'`
	
		msg -n "Partition device ${ANSI_BLUE}${DEVICE}${ANSI_DONE} "
	
		/usr/local/bin/sfdisk --force --no-reread /dev/${DEVICE} < ${i} \
			>> /tmp/stdout.log 2>>/tmp/stderr.log
	
		if [ "$?" != "0" ];
		then
			fail_msg
			fatal_error "Failed to partition disk device ${DEVICE} check /tmp/stdout.log or /tmp/stderr.log for details"
		else
			ok_msg
		fi
	done
fi
	
if [ -e /cloner/setup/raidconf ]
then
	header "Setting up software RAID devices"

	while read line
	do
		MD_DEVICE=`echo $line | awk '{print $1}'`
		MD_LEVEL=`echo $line | awk '{print $2}'`
		MD_DISK_QTY=`echo $line | awk '{print $3}'`
		MD_SPARE_QTY=`echo $line | awk '{print $4}'`
		MD_DISKS=`echo $line | awk '{print $5}'`
		MD_SPARES=`echo $line | awk '{print $6}'`

		T1=`echo $MD_DISKS | sed 's/,/ /'`
		T2=`echo $MD_SPARES | sed 's/,/ /'`
		MD_DISK_STRING="${T1} ${T2}"
		

		msg -n "Creating ${ANSI_BLUE}${MD_DEVICE}${ANSI_DONE} - $MD_LEVEL on $MD_DISK_QTY disk(s)"
		/usr/local/bin/mdadm --create ${MD_DEVICE} --force --run --level=${MD_LEVEL} --chunk=128 --raid-devices=${MD_DISK_QTY} --spare-devices=${MD_SPARE_QTY} ${MD_DISK_STRING} >> /tmp/stdout.log 2>> /tmp/stderr.log
	
	done < /cloner/setup/raidconf

fi

if [ -e /cloner/setup/pv_devices ]
then

	header "Setting up LVM groups"

	while read line
	do
		PV_DEVICE=`echo $line | awk '{print $1}'`
		PV_VG=`echo $line | awk '{print $2}'`
		PV_UUID=`echo $line | awk '{print $3}'`

		msg -n "Setting UUID on ${ANSI_BLUE}${PV_DEVICE}${ANSI_DONE}"
		/usr/local/bin/lvm pvcreate -ff -y --uuid ${PV_UUID} \
			--restorefile /cloner/setup/lvm.${PV_VG} \
			${PV_DEVICE} >> /tmp/stdout.log 2>> /tmp/stderr.log

		if [ "$?" != "0" ];
		then
			fail_msg
			fatal_error "Failed to restore LVM UUID ${PV_UUID} to ${PV_DEVICE}";
		else
			ok_msg
		fi
	done < /cloner/setup/pv_devices

	for i in `ls -1 /cloner/setup/lvm.*`
	do
		FILENAME=`basename $i`
		VG_NAME=`echo $FILENAME | cut -d"." -f2`	

		msg -n "Restoring volume group ${ANSI_BLUE}${VG_NAME}${ANSI_DONE}"
		/usr/local/bin/lvm vgcfgrestore -f $i ${VG_NAME} \
			>> /tmp/stdout.log 2>> /tmp/stderr.log

		if [ "$?" != "0" ];
		then
			fail_msg
			fatal_error "Failed to restore LVM volume ${VG_NAME}";
		else
			ok_msg
		fi
		msg -n "Activating volume group ${ANSI_BLUE}${VG_NAME}${ANSI_DONE}"
		/usr/local/bin/lvm vgchange -a y ${VG_NAME} \
			>> /tmp/stdout.log 2>> /tmp/stderr.log

		if [ "$?" != "0" ];
		then
			fail_msg
			fatal_error "Failed to bring LVM volume ${VG_NAME} online";
		else
			ok_msg
		fi
	done
fi

# we want to sort our filesystems via the mntpoint field so we can mount them in
# the correct order
sort -k2 /cloner/setup/filesystems \
	> /cloner/setup/filesystems.sorted 2>> /tmp/stderr.log

header "Creating/mounting filesystems"
while read line
do
	FS_DEVICE=`echo $line | awk '{print $1}'`
	FS_MNTPOINT=`echo $line | awk '{print $2}'`
	FS_TYPE=`echo $line | awk '{print $3}'`
	FS_LABEL=`echo $line | awk '{print $4}'`

	if [ "${_noddfs}" = "1" ]
	then
		msg "Skipping erasing first 5MB on partitions"
	else
		msg -n "Erasing first 5MB of data on partiion"
		dd if=/dev/zero of=${FS_DEVICE} bs=1M count=5 \
			>> /tmp/stdout.log 2>> /tmp/stderr.log
		ok_or_fail $?
	fi

	if [ "${_nomkfs}" = "" ]
	then

		msg -n "Creating ${ANSI_BLUE}${FS_TYPE}${ANSI_DONE} filesystem on ${ANSI_BLUE}${FS_DEVICE}${ANSI_DONE}"

		case "${FS_TYPE}"
		in
			ext3)
					CMD="/usr/local/bin/mke2fs -F -j ${FS_DEVICE}"
					if [ "${FS_LABEL}" != "" ]
					then	
						CMD="/usr/local/bin/mke2fs -F -L ${FS_LABEL} -j ${FS_DEVICE}"
					fi
	
					$CMD >> /tmp/stdout.log 2>> /tmp/stderr.log
					if [ "$?" = "0" ]
					then
						ok_msg
					else
						fail_msg
						fatal_error "Failed to make ext3 filesystem on ${FS_DEVICE}"
					fi
				;;
			ext2)
					CMD="/usr/local/bin/mke2fs -F ${FS_DEVICE}"
					if [ "${FS_LABEL}" != "" ]
					then	
						CMD="/usr/local/bin/mke2fs -F -L ${FS_LABEL} ${FS_DEVICE}"
					fi
	
					$CMD >> /tmp/stdout.log 2>> /tmp/stderr.log
					if [ "$?" = "0" ]
					then
						ok_msg
					else
						fail_msg
						fatal_error "Failed to make ext2 filesystem on ${FS_DEVICE}"
					fi
				;;
			xfs)
					/usr/local/bin/mkfs.xfs -f ${FS_DEVICE} \
						>> /tmp/stdout.log 2>> /tmp/stderr.log
					if [ "$?" = "0" ]
					then
						ok_msg
					else
						fail_msg
						fatal_error "Failed to make xfs filesystem on ${FS_DEVICE}"
					fi
				;;
	
			reiserfs)
					/usr/local/bin/mkreiserfs -ff ${FS_DEVICE} \
						>> /tmp/stdout.log 2>> /tmp/stderr.log
	
					if [ "$?" = "0" ]
					then
						ok_msg
					else
						fail_msg
						fatal_error "Failed to make reiserfs filesystem on ${FS_DEVICE}"
					fi
				;;
			swap)
					/usr/local/bin/mkswap -f ${FS_DEVICE} \
						>> /tmp/stdout.log 2>> /tmp/stderr.log
					if [ "$?" = "0" ]
					then
						ok_msg
					else
						fail_msg
						fatal_error "Failed to make swap filesystem on ${FS_DEVICE}"
					fi
	
					msg -n "Activating swap device ${FS_DEVICE}"
					swapon ${FS_DEVICE} >> /tmp/stdout.log 2>> /tmp/stderr.log
					if [ "$?" = "0" ]
					then
						ok_msg
					else
						fail_msg
						fatal_error "Failed to activate swap filesystem on ${FS_DEVICE}"
					fi
				;;
			*)
				fatal_error "Don't know how to handle filesystem type ${FS_TYPE}"
				;;
		esac

	fi
	
	# if it starts with a / it's going to be mounted
	if [ `echo ${FS_MNTPOINT} | grep '^/'` ]
	then
		MNT_POINT=`echo ${FS_MNTPOINT} | sed 's/^\///'`
		msg -n "Mounting ${ANSI_BLUE}${FS_DEVICE}${ANSI_DONE} on ${ANSI_BLUE}/cloner/mnt/${MNT_POINT}${ANSI_DONE}"

		mkdir -p /cloner/mnt/${MNT_POINT} >> /tmp/stdout.log 2>> /tmp/stderr.log

		mount -t ${FS_TYPE} ${FS_DEVICE} /cloner/mnt/${MNT_POINT} >> /tmp/stdout.log 2>> /tmp/stderr.log
		if [ "$?" = "0" ]
		then
			ok_msg
		else
			fail_msg
			fatal_error "Failed to mount ${FS_DEVICE} to /cloner/mnt/${MNT_POINT}"
		fi
	fi

done < /cloner/setup/filesystems.sorted


