#!/bin/bash

if [ "$UID" -ne 0 ]; then
        exec gnomesu -t "Document unlocking" \
        -m "Please enter the system password (root user)^\
in order to unlock documents." -c $0 -p
fi

# PATH and co
. /etc/profile

until [ "$db" ]; do
        db=`Xdialog --stdout --inputbox "Database to unlock documents:" \
	        10 40 "$db"` || exit
	db="${db// /}"
done


until [ "$trange" ]; do
        trange=`Xdialog --stdout --inputbox "Document range to unlock:
(e.g. 1-3 or 4)" \
	        10 40 "$trange"` || exit
	# remove spaces ...
	trange="${trange// /}"
	# remove invalid content
	if echo "$trange" | grep -q "^\([0-9]\+-[0-9]\+\|[0-9]\+\)$" ; then
                range="$trange"
        else
                Xdialog --infobox "Range not valid!" 8 28
        fi
done

unlock="localhost $db root $PASSWD unlock $range"
/home/cvs/archivista/jobs/avdbutility.pl $unlock 
error=$?

if [ $error -eq 0 ]; then
  Xdialog --msgbox "Documents $trange in database $db unlocked" 8 40
else
  Xdialog --msgbox "Error: Documents $trange in database $db could not be unlocked!" 8 40
fi
