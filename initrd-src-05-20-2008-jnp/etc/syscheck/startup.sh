#!/bin/ash -l

. /etc/library.sh
. /tmp/cmdline.dat

HTTP_SERVER="172.16.0.31"
HTTP_PORT="80"

post_file_to_server() {

    MSG=${1}
    URIPATH=${2}
    FILENAME=${3}

    if [ "${BREAKIN_ID}" -lt 0 ]
    then
        return 1
    fi

	URL="http://${HTTP_SERVER}:${HTTP_PORT}${URIPATH}"

    msg -n "$MSG -> ${HTTP_SERVER}:${HTTP_PORT}"

    /usr/local/bin/wget --server-response -O /tmp/post.out --post-file=${FILENAME} --timeout=10 \
        --tries=3 ${URL} >> /tmp/stdout.log 2>> /tmp/stderr.log

    if [ "$?" = 0 ]
    then
        ok_msg
        return 0
    else
        fail_msg
        return 1
    fi
}

check_values() {

	. /tmp/hardware.dat

	
	header "CPU information"
	i=0
	while [ "${i}" -lt "${CPU_COUNT}" ]
	do
			eval "speed=\$CPU_${i}_SPEED"
			eval "manuf=\$CPU_${i}_MANUFACTURER"
			eval "family=\$CPU_${i}_FAMILY"
			eval "version=\$CPU_${i}_VERSION"
			echo "  CPU ${i}   : $version - ${manuf} ${family} ${speed}"
			i=`expr ${i} + 1`
	done
	echo ""
	echo -n "Correct (y/n) [y] > "
	read confirm

	if [ "${confirm}" != "y" -a "${confirm}" != "Y" -a "${confirm}" != "" ]
	then
		return 1
	fi

	header "DIMM information"
	i=0
	while [ "${i}" -lt "${DIMM_COUNT}" ]
	do
			eval "name=\$DIMM_${i}_NAME"
			eval "size=\$DIMM_${i}_SIZE"
			eval "locator=\$DIMM_${i}_LOCATOR"
			echo "  DIMM ${i}   : ${name} / ${locator} ${size}"
			i=`expr ${i} + 1`
	done
	echo ""
	echo -n "Correct (y/n) [y] > "
	read confirm

	if [ "${confirm}" != "y" -a "${confirm}" != "Y" -a "${confirm}" != "" ]
	then
		return 1
	fi

	header "DISK information"
	i=0
	while [ "${i}" -lt "${DISK_COUNT}" ]
	do
			eval "name=\$DISK_${i}_DEV"
			eval "size=\$DISK_${i}_SIZE"
			eval "model=\$DISK_${i}_MODEL"
			echo "  DISK ${i}   : ${name} ${model} (${size}MB)"
			i=`expr ${i} + 1`
	done
	echo ""
	echo -n "Correct (y/n) [y] > "
	read confirm

	if [ "${confirm}" != "y" -a "${confirm}" != "Y" -a "${confirm}" != "" ]
	then
		return 1
	fi


	header "NIC information"
	i=0
	while [ "${i}" -lt "${NIC_COUNT}" ]
	do
			eval "name=\$NIC_${i}_DEV"
			eval "driver=\$NIC_${i}_DRIVER"
			eval "device=\$NIC_${i}_PCIDEV"
			eval "vendor=\$NIC_${i}_PCIVENDOR"
			echo "  NIC ${i}   : ${name} ${driver} (${device}:${vendor})"
			i=`expr ${i} + 1`
	done
	echo ""
	echo -n "Correct (y/n) [y] > "
	read confirm

	if [ "${confirm}" != "y" -a "${confirm}" != "Y" -a "${confirm}" != "" ]
	then
		return 1
	fi

}


header "Checking system against master"

CONTINUE=0
COUNT=0

while [ "${CONTINUE}" != 1 ]
do
	echo -n "Enter system serial number > "
	read serialnumber

	echo "SERIALNUMBER=\"$serialnumber\"" >> /tmp/submit.$$

	post_file_to_server "Sending serial number to server" "/cgi-bin/syscheck/check" /tmp/submit.$$
	if [ "$?" = "1" ]
	then
		fatal_error "Can't communicate with server!"
		exit
	fi

	if [ -e /tmp/post.out ]
	then
		. /tmp/post.out
		rm /tmp/post.out >> /tmp/stdout.log 2>> /tmp/stderr.log
	else
		fatal_error "Didn't get expected response back from server!"
	fi

	rm /tmp/submit.$$ >> /tmp/stdout.log 2>>/tmp/stderr.log

	if [ "${RESULT}" != "1" ]
	then
		msg ""
		msg "${ANSI_RED}${ERROR_MSG}${ANSI_DONE}"
		msg ""
		continue;
	fi

	header "Verify information is correct"
	
	echo "  Serial #    :  ${serialnumber}"
	echo "  Item name   :  ${ITEM_NAME}"
	echo "  Item type   :  ${GROUP_NAME}"
	echo "  Order       :  #${ORDER_ID} - ${ORDER_NAME}"
	echo "  Customer    :  ${CUSTOMER_NAME}"

	if [ "${MASTER_NAME}" != "" ]
	then
		echo "  Master      :  ${MASTER_NAME} / ${MASTER_SERIAL}"
	fi

	echo ""
	echo -n "Are the above values correct (y/n) [y] > "
	read confirm

	if [ "${confirm}" != "y" -a "${confirm}" != "Y" -a "${confirm}" != "" ]
	then
		continue
	fi

	if [ "${IS_MASTER}" = "1" ]
	then
		msg ""
		msg "${ANSI_RED}This serial # is a 'master' and can't be re-checked in.${ANSI_DONE}"
		msg ""
		continue
	fi

	if [ "${SYSCHECK_ID}" != "" ]
	then
		echo -n "The system has already been checked in, re-checkin (y/n) [y] > "
		read confirm
		if [ "${confirm}" != "y" -a "${confirm}" != "Y" -a "${confirm}" != "" ]
		then
			continue
		fi
	fi

	cp /tmp/hardware.dat /tmp/submit.$$ >> /tmp/stdout.log 2>> /tmp/stderr.log
	echo "SERIALNUMBER=\"$serialnumber\"" >> /tmp/submit.$$

	if [ "${MASTER_SERIAL}" = "" -o "${MASTER_SERIAL}" = "0"  ]
	then
		echo -n "No master found for this type of machine, use this one (y/n) [y] > "
		read confirm
		if [ "${confirm}" != "y" -a "${confirm}" != "Y" -a "${confirm}" != "" ]
		then
			continue
		fi
		check_values
		if [ "$?" = "1" ]
		then
			continue
		fi
		echo "MASTER=\"1\"" >> /tmp/submit.$$
	fi

	post_file_to_server "Sending hardware data to server" "/cgi-bin/syscheck/verified" /tmp/submit.$$
> /tmp/stdout.log 2>>/tmp/stderr.log


	if [ -e "/tmp/post.out" ]
	then
		. /tmp/post.out
	fi	

	if [ "${RESULT}" != "1" ]
	then
		msg "${ANSI_RED}"
		msg "${ERROR_MSG}"

		if [ "${CMP_ERROR_COUNT}" -gt 0 ]
		then
			i=0	
			while [ "${i}" -lt "${CMP_ERROR_COUNT}" ]
			do
				eval "MSG=\$CMP_ERROR_$i"
				msg "  $MSG"
				i=`expr ${i} + 1`
			done
		fi
		msg "${ANSI_DONE}"
		continue
	else

		if [ "${_startcloner}" = "1" ]
		then
			exec /etc/cloner/startup.sh
		elif [ "${_startbreakin}" = "1" ]
		then
			exec /etc/breakin/startup.sh
		else 
			msg "${ANSI_GREEN}"	
			echo ""
			echo "***************************************************************"
			echo "*                                                             *"
			echo "*               System checked into sysman                    *"
			echo "*                                                             *"
			echo "***************************************************************"
			msg "${ANSI_DONE}"
			echo "Either reboot system or press [ENTER] for prompt: "
			echo ""
			read line

		fi
	fi
	break
done
exit
