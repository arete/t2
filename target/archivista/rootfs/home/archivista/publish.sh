#!/bin/bash

pscount=`ps --no-headers -C publish.sh | wc -l`

# 2 due to foking a sub-process above :-(
if [ $pscount -gt 2 ] ; then
	Xdialog --no-cancel --title 'Archive publishing' --msgbox \
	        "There is already a publishing process running! Only one instance
can compess the system, try again later." 0 0
	exit
fi

if [ "$UID" -ne 0 ]; then
        exec gnomesu -t "Archive publishing" \
        -m "Please enter the system password (root user)^\
in order to publish the archive." -c $0
fi

# PATH and co
. /etc/profile

# Xdialog and friends
export DISPLAY=:0

set -e

livedir=/home/data/livecd
dbdir=/home/data/archivista/mysql

cleanup ()
{
	rm -rf live.squash boot root
}

# database selection from the user
cd $dbdir
i=0
for x in * ; do
	[ -d "$x" ] || continue
	case "$x" in
		mysql|test) continue ;;
	esac
	dbs[$((i++))]="$i"
	dbs[$((i++))]="$x"
	dbs[$((i++))]="on"
done

while [ -z "$d" ]; do
	d=`Xdialog --stdout --password --no-tags --separate-output \
	   --title 'Archive publishing' --checklist \
	   "Choose the databases to be published." 0 0 3 "${dbs[@]}"` || exit
	[ "$d" ] || Xdialog --no-cancel --title 'Archive publishing' --msgbox \
	                    "You need to select at least one database!" 0 0
done

# generate exclude list and find out if the archivista db is selected
n=$i; i=0
d=" $d " # terminating space
dbexclude=
archivistadb=1
while [ $i -lt $n ]; do
	# selected?
	if [ "${d/ $i /}" != "$d" ]; then
		echo $i selected
	else
		echo $i not seleted
		[ "${dbs[$((i+1))]}" = archivista ] && archivistadb=0
		dbexclude="$dbexclude $dbdir/${dbs[$((i+1))]}"
	fi

  : $(( i += 3 ))
done

echo database exclude: $dbexclude
echo archivista db: $archivistadb

mkdir -p $livedir/root ; cd $livedir
cleanup

# list of top-level dirs
dirs=
for dir in /* ; do
	[ -d $dir ] || continue
	case $dir in
		# do not include the virtual fs or mounted volumes
		/dev|/proc|/sys|/tmp|/mnt|/media)
			mkdir -p root$dir
			continue
			;;
	esac
	dirs="$dirs $dir"
done

chmod 1777 root/tmp

# approximate output size
# disc usage
d_size=`df -B 1000000 -P /home/data / | tr -s ' ' | cut -d ' ' -f 3 |
        sed '1d ; $!s/$/+\\\/' | bc`
# substract excluded dbs and livecd
f_size=`du -B 1000000 -sc $dbexclude $livedir | tail -n 1 | cut -f 1`

c_size=$(( (d_size - f_size) / 3 )) # a lot of text, thus more than 2

Xdialog --cancel-label=Cancel --ok-label=Continue --title "Archive publishing" \
--yesno "Based on the current hard disc usage ($d_size - $f_size MB),
the estimated media utilization will be $c_size MB." 0 0 || exit

unint_xdialog_w_file ()
{
	touch $2
	while true; do
		Xdialog --no-close --no-buttons --title 'Archive publishing' \
		 --infobox "$1\n("`ls -sh $2 | cut -d ' ' -f1`"B done)" 0 0 5000
	done
}

# undo stuff done after installation
cp /home/archivista/.fluxbox/menu{.orig,}

rc apache stop
rc mysql stop

unint_xdialog_w_file "The database archive and the currently running system
are beeing compressed. This process will take quite some time." live.squash &
set -x
mksquashfs $dirs ./root/ live.squash -noappend -info -e /home/data/t2-trunk $livedir $dbexclude
set +x
kill %- 2>/dev/null || true # the Xdialog


unint_xdialog_w_file "The final disc image is beeing created.
This process will take a few minutes." av.iso &

# copy initrd, grub, ...
cp -ar /boot-cd boot

isoname=`date "+%Y%m%d-%H%M"`

# mkisofs, heavily copied out of the T2 sources, since there we add all the
# magic glue automagically ,-)))
mkisofs -q -r -T -J -l -o $isoname -A "Archivista Box" \
        -publisher 'Archivista Box based on the T2 SDE' \
        -b boot/grub/stage2_eltorito -no-emul-boot -boot-load-size 4 -boot-info-table \
        --graft-points live.squash boot=boot

kill %- 2> /dev/null || true # the Xdialog

rc mysql start
rc apache start

cleanup

Xdialog --msgbox "Disc image generation completed.
The ISO image filename is $PWD/$isoname." 0 0

