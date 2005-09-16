#!/bin/bash

if [ "$UID" -ne 0 ]; then
        exec gnomesu -t "Perform backup" \
        -m "Please enter the system password (root user)^\
in order to immediatly perform a backup." -c $0
fi

# PATH and co
. /etc/profile

# Xdialog and friends
export DISPLAY=:0

(
	rc mysql stop > /dev/null
	/home/archivista/rescan-scsi-bus.sh
	flexbackup -set all && mt -f /dev/nst0 rewoffl
	rc mysql start > /dev/null
) 2>&1 | Xdialog --no-cancel --log - 20 60

