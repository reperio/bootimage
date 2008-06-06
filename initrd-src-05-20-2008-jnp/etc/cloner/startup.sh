#!/bin/ash

. /etc/library.sh
. /etc/cloner/include.sh

# first thing we do is bring up the network interface if we are not
# installing from a sourcepath
if [ "${_srcpath}" != "" ]
then
	/etc/cloner/detect_cd.sh
fi

/etc/cloner/get_setup.sh

# if we are supposed to automatically format disks
if [ "${_manualdisk}" = "" ]
then
	/etc/cloner/prep_disks.sh
	/etc/cloner/installer.sh

	header "Cloner install finished"
	echo -e "The cloner install has finished successfully.  You may now reboot"
	echo -e "the machine.  If you would like to re-mount the destination filesystems"
	echo -e "to make any changes manually please run ${ANSI_BLUE}/etc/cloner/remount-fs.sh${ANSI_DONE}"
	echo -e ""
	echo -en "Press ${ANSI_BLUE}[ENTER]${ANSI_DONE} for a command prompt"
	read PROMPT

else

	header "Partition and format disks"
	echo -e "You have selected to manually partition and format your hard disk drives"
	echo -e "please do that now, and mount them under /cloner/mnt as they will be in"
	echo -e "the installed OS.  When finished execute /etc/cloner/installer.sh on the command"
	echo -e "line to finish the installation of this system."

	echo -en "Press ${ANSI_BLUE}[ENTER]${ANSI_DONE} for a command prompt"
	read PROMPT
fi
