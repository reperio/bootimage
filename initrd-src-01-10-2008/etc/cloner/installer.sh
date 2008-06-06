#!/bin/ash

. /etc/library.sh
. /etc/cloner/include.sh
. /tmp/cmdline.dat

# TODO
#  * Further testing of GRUB / LILO bootloader

header "Starting the installation process"

# --------------
#  Perform a multicast install
# --------------
if [ "${_multicast}" = "1" ]
then

	msg "Starting multicast receiver, server will initiate transfer"
	/usr/local/bin/udp-receiver --nokbd --pipe 'tar -xvf - -C /cloner/mnt'

	if [ "$?" = "0" ]
	then
		ok_msg
	else
		fail_msg
		fatal_error "Failed to untar multicasted image"
	fi

# --------------
#  A CD-DVD based install
# --------------
elif [ "${_srcpath}" != "" ]
then
	msg "Starting the unpacking from CD/DVD-ROM"

	# change to our install directory
	cd /cloner/mnt >> /tmp/stdout.log 2>>/tmp/stderr.log

	if [ -e /cloner/setup/disk_size ]
	then
		. /cloner/setup/disk_size
	else
		fatal_error "No disk size specified on setup directory"
	fi

	afio -i -Z -v -s $DISK_SIZE -H /etc/cloner/switch_cd.sh \
		/mnt/media/${_image}.afio

	if [ "$?" != 0 ]
	then
		fail_msg
		fatal_error "Failed to extract filesystem from CD/DVD drive"
	fi

	# revert back to our old directory
	cd - >> /tmp/stdout.log 2>>/tmp/stderr.log

# --------------
#  A standard network RSYNC based install
# --------------
else

	#msg "The installation process can take a while, check ${ANSI_RED}[ALT-F4]${ANSI_DONE} to view progress"

	msg -n "Syncing data from ${ANSI_BLUE}${_server}${ANSI_DONE} image ${ANSI_BLUE}${_image}${ANSI_DONE}"
	/usr/local/bin/rsync -avz --numeric-ids \
		${_server}::${CLONER_IMAGE_PATH}/${_image}/data/  /cloner/mnt/
	if [ "$?" = "0" ]
	then
		ok_msg
	else
		fail_msg
		fatal_error "Failed to sync filesystem data from server!"
	fi
	
fi
	
# remake an directories we excluded from our rsync process
sort -k1 /cloner/setup/makedirectories \
	> /cloner/setup/makedirectories.sorted 2>> /tmp/stderr.log

header "Making missing directories"
while read line
do

	DIR=`echo $line | awk '{print $1}'`
	DIR_MODE=`echo $line | awk '{print $2}'`
	DIR_UID=`echo $line | awk '{print $3}'`
	DIR_GID=`echo $line | awk '{print $4}'`

	if [ "${DIR}" != "" ]
	then
		msg -n "Making directory ${ANSI_BLUE}${DIR}${ANSI_DONE}"
		mkdir -p /cloner/mnt/${DIR} >> /tmp/stdout.log \
			2>> /tmp/stderr.log

		chmod ${DIR_MODE} /cloner/mnt/${DIR} >> \
			/tmp/stdout.log 2>> /tmp/stderr.log
	
		chown ${DIR_UID}:${DIR_GID} /cloner/mnt/${DIR} \
			>> /tmp/stdout.log 2>> /tmp/stderr.log
	
		if [ "$?" = "0" ]
		then
			ok_msg
		else
			fail_msg
		fi
	fi

done < /cloner/setup/makedirectories.sorted
	
if [ "${_node}" != "" ]
then

	if [ "${_srcpath}" != "" ]
	then
		header "Installing node specific data"
		msg -n "Syning node ${ANSI_BLUE}${_node}${ANSI_DONE} data from /mnt/media"
		rsync -avz -I --numeric-ids --exclude /.valid \
			/cloner/setup/node/ /cloner/mnt \
			>> /tmp/stdout.log 2>> /tmp/stderr.log

		if [ "$?" = "0" ]
		then
			ok_msg
		else
			fail_msg
			fatal_error "Failed to sync node data from CD/DVD"
		fi
	else
		header "Installing node specific data"
		msg -n "Syning node ${ANSI_BLUE}${_node}${ANSI_DONE} data from ${_server}"

		rsync -avz --numeric-ids --exclude /.valid \
			${_server}::${CLONER_IMAGE_PATH}/${_image}/nodes/${_node}/ \
			/cloner/mnt >> /tmp/stdout.log 2>> /tmp/stderr.log
		if [ "$?" = "0" ]
		then
			ok_msg
		else
			fail_msg
			fatal_error "Failed to sync node data from server!"
		fi
	fi
fi

header "Installing bootloader"
while read line
do
	BL_DEVICE=`echo $line | awk '{print $1}'`
	BL_TYPE=`echo $line | awk '{print $2}'`

	if [ "${BL_TYPE}" = "grub" ]
	then
		msg -n "Installing grub bootloader on ${ANSI_BLUE}${BL_DEVICE}${ANSI_DONE}"

		GRUB_PATH=""
		if [ -x /cloner/mnt/sbin/grub-install ]
		then
			GRUB_PATH="/sbin/grub-install"
		elif  [ -x /cloner/mnt/usr/sbin/grub-install ]
		then
			GRUB_PATH="/usr/sbin/grub-install"
		else
			fatal_error "Can't find the grub-install binary on mounted filesystem, no bootloader installed"
		fi

		chroot /cloner/mnt ${GRUB_PATH} --no-floppy ${BL_DEVICE} \
			>> /tmp/stdout.log 2>> /tmp/stderr.log
		if [ "$?" = "0" ]
		then
			ok_msg
		else
			fail_msg
			msg -n "Trying alternative grub installation "
			echo "root (hd0,0)" > /cloner/mnt/grub.txt
			echo "setup (hd0)" >> /cloner/mnt/grub.txt

			chroot /cloner/mnt ""/sbin/grub --device-map=/boot/grub/device.map --no-floppy --batch < /cloner/mnt/grub.txt"" \ 
				>> /tmp/stdout.log 2>> /tmp/stderr.log
			if [ "$?" = "0" ]
			then
				ok_msg
			else
				fail_msg
				fatal_error "Failed to install grub bootloader"
			fi
		fi
	elif [ "${BL_TYPE}" = "lilo" ]
	then
		msg -n "Installing lilo bootloader on ${ANSI_BLUE}${BL_DEVICE}${ANSI_DONE}"
		chroot /cloner/mnt /sbin/lilo >> /tmp/stdout.log 2>> /tmp/stderr.log
		if [ "$?" = "0" ]
		then
			ok_msg
		else
			fail_msg
			fatal_error "Failed to install grub bootloader"
		fi
	fi

done < /cloner/setup/bootloader

# we want to sort our filesystems via the mntpoint field so we can unmount them in
# the reverse order
sort -r -k2 /cloner/setup/filesystems \
	> /cloner/setup/filesystems.revsorted 2>> /tmp/stderr.log

header "Unmounting filesystems"
while read line
do
	FS_DEVICE=`echo $line | awk '{print $1}'`
	FS_MNTPOINT=`echo $line | awk '{print $2}'`
	FS_TYPE=`echo $line | awk '{print $3}'`
	FS_LABEL=`echo $line | awk '{print $4}'`

	case "${FS_TYPE}"
	in
		swap)
			msg -n "Turning off swap partitions"
			swapoff ${FS_DEVICE} >> /tmp/stdout.log 2>> /tmp/stderr.log
			ok_or_fail $?
			;;
		*)
			msg -n "Unmounting ${FS_DEVICE} -> ${FS_MNTPOINT}"
			umount /cloner/mnt${FS_MNTPOINT} >> /tmp/stdout.log 2>> /tmp/stderr.log
			ok_or_fail $?
			;;
	esac
done < /cloner/setup/filesystems.revsorted

