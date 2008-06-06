#!/bin/ash

. /etc/library.sh
. /etc/cloner/include.sh
. /tmp/cmdline.dat

# find the CD-ROM device and create a symlink to it

header "Trying to locate CD/DVD-ROM device"

for i in `ls -1 /dev/cdrom*`
do
	msg -n "Mounting ${ANSI_BLUE}${i}${ANSI_DONE} on /mnt/media"
	mount -t udf ${i} /mnt/media >> /tmp/stdout.log \
		2>> /tmp/stderr.log

	if [ "$?" = "0" ]
	then
		ok_msg
		ln -s ${i} /dev/media >> /tmp/stdout.log \
			2>> /tmp/stderr.log	
		break
	else
		fail_msg
	fi
done
	
if [ ! -e /dev/media ]
then
	fatal_error "Can't find a valid CD/DVD-ROM on this machine"
fi
