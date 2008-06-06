#!/bin/ash

. /etc/library.sh
. /etc/cloner/include.sh
. /tmp/cmdline.dat

VOLUME=${1}
FILENAME=${2}
CONTINUE=0

header "End of CD/DVD-ROM reached"

while  [ "$CONTINUE" = "0" ]; do
    umount /mnt/media >> /tmp/stdout.log 2>> /tmp/stderr.log

    msg "Please insert disk ${ANSI_BLUE}#${VOLUME}${ANSI_DONE} and press enter:"
    read INPUT <&1

    mount -t udf /dev/media /mnt/media >> /tmp/stdout.log \
		2>> /tmp/stderr.log

    if [ -e "/mnt/media/DISK_${VOLUME}" ]; then
        CONTINUE=1
    else
        msg "${ANSI_RED}**** INVALID DISK ****${ANSI_DONE}"
    fi
done

exit
