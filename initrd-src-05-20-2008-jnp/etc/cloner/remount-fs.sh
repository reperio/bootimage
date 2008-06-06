#!/bin/ash

# we want to sort our filesystems via the mntpoint field so we can mount them in
# the correct order
sort -k2 /cloner/setup/filesystems \
	> /cloner/setup/filesystems.sorted 2>> /tmp/stderr.log

header "Mounting filesystems"
while read line
do
	FS_DEVICE=`echo $line | awk '{print $1}'`
	FS_MNTPOINT=`echo $line | awk '{print $2}'`
	FS_TYPE=`echo $line | awk '{print $3}'`
	FS_LABEL=`echo $line | awk '{print $4}'`

	
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

