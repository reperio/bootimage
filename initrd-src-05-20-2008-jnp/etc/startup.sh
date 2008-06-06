#!/bin/ash -l

. /etc/library.sh

# only really run this once, if the file exists we drop to a shell instead
# this allows us to respawn from inittab
if [ -e /tmp/ranonce ];
then
	exec /bin/ash
fi

touch /tmp/ranonce


ARGS=""

echo "" > /tmp/cmdline.dat
for i in `cat /proc/cmdline`
do
	case ${i}
	in
		*=*)
			KEY=`echo ${i} | cut -d"=" -f1`
			VALUE=`echo ${i} | cut -d"=" -f2`

			if [ "${KEY}" != "" ];
			then
				export _${KEY}="${VALUE}"
				echo "_${KEY}='${VALUE}'" >> /tmp/cmdline.dat
			fi
		;;
	esac
done

if [ "${_sshpasswd}" != "" ]
then
	#echo "root:${_sshpasswd}" | /usr/sbin/chpasswd
	echo "ssh:${_sshpasswd}" | /usr/sbin/chpasswd

	/usr/local/sbin/dropbear -p :22 > /var/log/sshd.log 2>&1
fi

. /etc/hardware.sh

if [ "${_startup}" = "" ]
then
	echo "A startup option must be specified on the kernel command line"
	exit
fi

/etc/${_startup}/startup.sh
