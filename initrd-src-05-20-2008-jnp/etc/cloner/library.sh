#!/bin/ash

eval `stty size 2>/dev/null | (read L C; echo LINES=${L:-24} COLUMNS=${C:-80})`

PRODUCT_NAME="Advanced Clustering's Cloner"
PRODUCT_VERSION="2.1"

CLONER_IMAGE_PATH="cloner-2/images"
CLONER_HOST_PATH="cloner-2/hosts"


ANSI_GREEN="\033[1;32m"
ANSI_RED="\033[1;31m"
ANSI_BLUE="\033[1;34m"
ANSI_PURPLE="\033[1;35m"
ANSI_LEFT="\033[${COLUMNS}G\033[10D"
ANSI_DONE="\033[0m"

PRINT_OK=`echo -n ${ANSI_LEFT}${ANSI_GREEN} [ OK ] ${ANSI_DONE}`
PRINT_FAIL=`echo -n ${ANSI_LEFT}${ANSI_RED} [ FAIL ] ${ANSI_DONE}`

# if we have a settings file, load that
if [ -e "/cloner/settings.conf" ]
then
	. /cloner/settings.conf
fi

msg() {
	ARG1=$1
	ARG2=$2

	if [ "$ARG1" = "-n" ]
	then
		echo -en ${ARG2}
	else 
		echo -e ${ARG1}
	fi
}


fail_msg() {
	MSG=$1

	# echo wget a error message to the server
	msg "${PRINT_FAIL}"
}

ok_msg() {
	MSG=$1

	# echo wget a error message to the server
	msg "${PRINT_OK}"
}

ok_or_fail() {
	RETURN=$1

	if [ "$RETURN" = "0" ]
	then
		ok_msg
	else
		fail_msg
	fi
}

header() {
	MSG=$1

	msg -n "${ANSI_GREEN}"
	msg "================================="
	msg -n "${ANSI_BLUE}"
	msg " ${MSG}"
	msg -n "${ANSI_GREEN}"
	msg "================================="
	msg -n ${ANSI_DONE}

}

fatal_error() {
	MSG=$1

	msg ""
	msg -n "${ANSI_RED}"
	msg "========================================================"
	msg "           Fatal Error - halting ${PRODUCT_NAME} ${PRODUCT_VERSION}"
	msg "========================================================"
	msg -n "${ANSI_BLUE}"
	msg " ${MSG}"
	msg -n "${ANSI_RED}"
	msg "========================================================"
	msg -n ${ANSI_DONE}
	msg ""
	exit 1

}

modprobe_module() {

	MODULE_NAME=${1}

	msg -n "Trying to load ${ANSI_BLUE}${MODULE_NAME}${ANSI_DONE}"
	/sbin/modprobe "${MODULE_NAME}"  >> /tmp/stdout.log 2>> /tmp/stderr.log
	if [ "$?" = "1" ];
	then
		fail_msg
		return 1
	else
		ok_msg
		return 0
	fi
}

load_module() {

	MODULE_PATH=${1}
	MODULE_NAME=`basename ${MODULE_PATH}`
	MODULE_BARE=`echo ${MODULE_NAME} | cut -d . -f 1`

	msg -n "Trying to load ${ANSI_BLUE}${MODULE_NAME}${ANSI_DONE}"
	# /sbin/insmod "${MODULE_PATH}"  >> /tmp/stdout.log 2>> /tmp/stderr.log
	/sbin/modprobe "${MODULE_BARE}"  >> /tmp/stdout.log 2>> /tmp/stderr.log
	if [ "$?" = "1" ];
	then
		fail_msg
		return 1
	else
		ok_msg
		return 0
	fi
}


replace_setting() {

	KEY=${1}
	VALUE=${2}

	sed 's/${KEY}=.*//' /cloner/settings.conf > /tmp/settings.new
	echo "${KEY}=\"${VALUE}\"" >> /tmp/settings.new

	mv /tmp/settings.new /cloner/settings.conf
}
