#!/bin/sh

FOUND_ERROR=0
SYSLOG_PATH=/var/log/messages
[ -f /tmp/.syslog_pos ] || echo -n 0 > /tmp/.syslog_pos

CURPOS=$(cat /tmp/.syslog_pos)
LOG_LINES=$(/usr/bin/wc -l ${SYSLOG_PATH})

if [ $CURPOS -lt $LOG_LINES ]
then
	if /usr/bin/tail -n +${CURPOS} | /bin/grep -q -E '(mce: \[Hardware)|(mce_record:)' 2>/dev/null 1>&2
	then
		expr $LOG_LINES + 1 > /tmp/.syslog_pos
		/usr/bin/tail -n +${CURPOS} | /bin/grep -E '(mce: \[Hardware)|(mce_record:)' 2>/dev/null
		FOUND_ERROR=1
	fi
fi

sleep 10
exit $FOUND_ERROR

