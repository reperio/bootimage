#!/bin/ash

. /etc/library.sh
. /etc/cloner/include.sh
. /tmp/hardware.dat

write_client_conf () {
	# Takes $SERVER, $IMAGE and $NODE as arguments and makes 
	# /etc/cloner-client.conf
	mkdir -p /cloner/setup/node/etc
	if [ "${1}x" != "x" ]; then
		echo "SERVER=${1}" >> /cloner/setup/node/etc/cloner-client.conf
	fi
	if [ "${2}x" != "x" ]; then
		echo "IMAGE=${2}" >> /cloner/setup/node/etc/cloner-client.conf
	fi
	if [ "${3}x" != "x" ]; then
		echo "NODE=${3}" >> /cloner/setup/node/etc/cloner-client.conf
	fi
		
}

if [ "${_srcpath}" != "" ]
then
	header "Copying setup information from ${_srcpath}"
else
	if [ "${_server}" = "" ]
	then
		fatal_error "The server must be specified on the command line"
		exit
	fi
	header "Getting setup information from cloner server (${_server})"
fi

if [ "${_image}" = "" ]
then
	# user has not specified the cloner image from the command line

	USE_SETTINGS=""

	I=0
	while [ "${I}" -lt "${NIC_COUNT}" ]
	do
		MACADDR=`eval "echo \\\${NIC_${I}_HWADDR}"`
		ADDR=`echo ${MACADDR} | sed 's/://g'`

		msg -n "Asking server for setup information for ${ADDR}"
		rsync -v ${_server}::${CLONER_HOST_PATH}/${ADDR} \
			/cloner/setup/${ADDR} >> /tmp/stdout.log 2>> /tmp/stderr.log
		if [ "$?" = 0 ]
		then
			ok_msg
			USE_SETTINGS=${ADDR}
			break
		else
			fail_msg
		fi

		I=`expr ${I} + 1`
	done

	if [ "${USE_SETTINGS}" != "" ]
	then
		. /cloner/setup/${USE_SETTINGS}	
		msg "Using settings image=${ANSI_BLUE}${IMAGE}${ANSI_DONE} node=${ANSI_BLUE}${NODE}${ANSI_DONE}"

		replace_setting "_image" "${IMAGE}"
		replace_setting "_node" "${NODE}"
	fi
fi

if [ "${_image}" = "" ]
then
	fatal_error "No image was specified or downloaded from the server"
fi
	
# if we are installing from a disk or CD-ROM

if [ "${_srcpath}" != "" ]
then
	msg -n "Copying setup data for image ${_image}"
	rsync -v /mnt/media/setup/* /cloner/setup \
		>> /tmp/stdout.log 2>> /tmp/stderr.log
	if [ "$?" = 0 ]
	then
		ok_msg
	else
		fail_msg
	
		fatal_error "Can't get setup information from /mnt/media/setup"
	fi

	if [ "${_node}" != "" ]
	then
		msg -n "Copying node specific data for image=${_image} node=${_node}"
		cp -av /mnt/media/setup/nodes/${_node}/* /cloner/setup/node \
			>> /tmp/stdout.log 2>> /tmp/stderr.log
		if [ "$?" = 0 ]
		then
			ok_msg
		else
			fail_msg
			fatal_error "Can't get node specific information from /mnt/media"
		fi
	fi

# we are installing from the network
else
	msg -n "Downloading setup data for image ${_image}"
	rsync -v ${_server}::${CLONER_IMAGE_PATH}/${_image}/* /cloner/setup \
		>> /tmp/stdout.log 2>> /tmp/stderr.log
	if [ "$?" = 0 ]
	then
		ok_msg
	else
		fail_msg
	
		fatal_error "Can't get setup information from ${_server}::${CLONER_IMAGE_PATH}/${_image}"
	fi

	if [ "${_node}" != "" ]
	then
		msg -n "Downloading node specific data for image=${_image} node=${_node}"
		rsync -av ${_server}::${CLONER_IMAGE_PATH}/${_image}/nodes/${_node}/ \
			/cloner/setup/node >> /tmp/stdout.log 2>> /tmp/stderr.log
	
		if [ "$?" = 0 ]
		then
			ok_msg
		else
			fail_msg
	
			fatal_error "Can't get node specific information from ${_server}::${CLONER_IMAGE_PATH}/${_image}/nodes/${_node}"
		fi
		msg -n "Writing /etc/cloner-client.conf"
		write_client_conf ${_server} ${_image} ${_node}
		if [ "$?" = 0 ]
		then
			ok_msg
		else
			fail_msg
	
			fatal_error "Could not write /cloner/setup/etc/cloner-client.conf"
		fi
	fi
fi
