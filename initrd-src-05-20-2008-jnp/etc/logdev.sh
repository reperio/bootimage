#!/bin/ash

# mount a logging device
for i in `ls -1d /sys/block/sd[a-z] /sys/block/hd[a-z] 2>/dev/null`
do
	REMOVABLE=$(< ${i}/removable)
	if [ "${REMOVABLE}" != 1 ]
	then
		ls -l ${i}/device | grep usb > /dev/null
		if [ $? != 0 ]
		then
			continue # skip non-removable, non-usb devices
		fi
	fi
	DEV_NAME=`basename ${i}`
	vol_id -x /dev/${DEV_NAME} > /tmp/vol_id.tmp
	if [ $? != 0 ] # no file system found
	then
		for j in `ls -1d ${i}/?d?[0-9] 2>/dev/null`
		do
			DEV_NAME=`basename ${j}`
			vol_id -x /dev/${DEV_NAME} > /tmp/vol_id.tmp
			if [ $? = 0 ]
			then
				#source /tmp/vol_id.tmp # might use these variables some day
				mount /dev/${DEV_NAME} /var/logdev
				touch /var/logdev/breakin.log
				echo "Logging device found at ${DEV_NAME}."
				exit 0
			fi
		done
	else # found file system
		#source /tmp/vol_id.tmp # might use these variables some day
		mount /dev/${DEV_NAME} /var/logdev
		touch /var/logdev/breakin.log
		echo "Logging device found at ${DEV_NAME}."
		exit 0
	fi
done

echo "No logging device found."

